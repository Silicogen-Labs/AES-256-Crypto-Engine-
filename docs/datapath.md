# AES-256 Datapath Specification

## 1. Overview

This document describes the complete datapath architecture including signal widths, mux controls, and data flow for each cycle of operation.

## 2. Top-Level Datapath

```
┌────────────────────────────────────────────────────────────────────────────┐
│                              DATAPATH BLOCK                                 │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   INPUTS                                                                    │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐                   │
│   │  key     │  │ data_in  │  │  mode    │  │  start   │                   │
│   │[255:0]   │  │[127:0]   │  │  [0:0]   │  │  [0:0]   │                   │
│   └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘                   │
│        │             │             │             │                          │
│        ▼             ▼             ▼             ▼                          │
│   ┌─────────────────────────────────────────────────────┐                  │
│   │              INPUT REGISTERS (clocked)               │                  │
│   │  key_reg[255:0] │ data_in_reg[127:0] │ mode_reg      │                  │
│   └─────────────────────────────────────────────────────┘                  │
│                          │                                                 │
│                          ▼                                                 │
│   ┌─────────────────────────────────────────────────────┐                  │
│   │              KEY EXPANSION BLOCK                     │                  │
│   │                                                      │                  │
│   │  Input:  key_reg[255:0]                             │                  │
│   │  Output: round_key[0..14][127:0]  (15 round keys)   │                  │
│   │                                                      │                  │
│   │  Internal: w[0..59][31:0]  (60 expanded words)      │                  │
│   │            key_cnt[5:0]    (expansion counter)       │                  │
│   └─────────────────────────────────────────────────────┘                  │
│                          │                                                 │
│                          ▼                                                 │
│   ┌─────────────────────────────────────────────────────┐                  │
│   │              STATE REGISTER                          │                  │
│   │                                                      │                  │
│   │  state[127:0] = {col3, col2, col1, col0}            │                  │
│   │                                                      │                  │
│   │  col0 = state[31:0]   = {s0, s1, s2, s3}            │                  │
│   │  col1 = state[63:32]  = {s4, s5, s6, s7}            │                  │
│   │  col2 = state[95:64]  = {s8, s9, s10, s11}          │                  │
│   │  col3 = state[127:96] = {s12, s13, s14, s15}        │                  │
│   │                                                      │                  │
│   │  Where s0-s15 are bytes in column-major order        │                  │
│   └─────────────────────────────────────────────────────┘                  │
│                          │                                                 │
│                          ▼                                                 │
│   ┌─────────────────────────────────────────────────────┐                  │
│   │              ROUND DATAPATH MUX                      │                  │
│   │                                                      │                  │
│   │  if (round_cnt == 0)                                 │                  │
│   │      state_out = AddRoundKey(state, round_key[0])   │                  │
│   │  else if (mode == 0)  // encrypt                     │                  │
│   │      state_out = aes_round(state, round_key[i])     │                  │
│   │  else                 // decrypt                     │                  │
│   │      state_out = aes_inv_round(state, round_key[14-i│                  │
│   └─────────────────────────────────────────────────────┘                  │
│                          │                                                 │
│                          ▼                                                 │
│   ┌─────────────────────────────────────────────────────┐                  │
│   │              OUTPUT                                  │                  │
│   │  data_out[127:0] = state (when valid=1)             │                  │
│   └─────────────────────────────────────────────────────┘                  │
│                                                                             │
└────────────────────────────────────────────────────────────────────────────┘
```

## 3. State Matrix Organization

### 3.1 Byte to State Mapping

Input data_in[127:0] maps to AES state matrix:

```
Input byte order (big-endian):
data_in[127:120] = byte 0  (MSB)
data_in[119:112] = byte 1
...
data_in[7:0]     = byte 15 (LSB)

State matrix (column-major storage):
        Row 0   Row 1   Row 2   Row 3
       ┌───────┬───────┬───────┬───────┐
Col 0  │ s0    │ s1    │ s2    │ s3    │  = state[31:0]   = {data_in[127:120], ...}
       ├───────┼───────┼───────┼───────┤
Col 1  │ s4    │ s5    │ s6    │ s7    │  = state[63:32]
       ├───────┼───────┼───────┼───────┤
Col 2  │ s8    │ s9    │ s10   │ s11   │  = state[95:64]
       ├───────┼───────┼───────┼───────┤
Col 3  │ s12   │ s13   │ s14   │ s15   │  = state[127:96]
       └───────┴───────┴───────┴───────┘
```

### 3.2 State Register Bit Fields

```verilog
wire [31:0] state_col0 = state[31:0];
wire [31:0] state_col1 = state[63:32];
wire [31:0] state_col2 = state[95:64];
wire [31:0] state_col3 = state[127:96];

// Byte extraction from column 0
wire [7:0] s0 = state_col0[31:24];  // Row 0, Col 0
wire [7:0] s1 = state_col0[23:16];  // Row 1, Col 0
wire [7:0] s2 = state_col0[15:8];   // Row 2, Col 0
wire [7:0] s3 = state_col0[7:0];    // Row 3, Col 0
```

## 4. Key Expansion Datapath

### 4.1 Key Expansion Block Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    aes_key_expansion                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Input: key[255:0]                                               │
│                                                                  │
│  w[0]  = key[255:224]  ┐                                         │
│  w[1]  = key[223:192]  │                                         │
│  w[2]  = key[191:160]  ├─► Initial words (cycles 0-7)           │
│  w[3]  = key[159:128]  │                                         │
│  w[4]  = key[127:96]   │                                         │
│  w[5]  = key[95:64]    │                                         │
│  w[6]  = key[63:32]    │                                         │
│  w[7]  = key[31:0]     ┘                                         │
│                                                                  │
│  For i = 8 to 59:                                                │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  temp = w[i-1]                                          │    │
│  │                                                         │    │
│  │  if (i % 8 == 0)                                        │    │
│  │      temp = SubWord(RotWord(temp)) XOR Rcon[i/8]        │    │
│  │  else if (i % 8 == 4)                                   │    │
│  │      temp = SubWord(temp)                               │    │
│  │                                                         │    │
│  │  w[i] = w[i-8] XOR temp                                 │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  Output: round_key[i] = {w[4i], w[4i+1], w[4i+2], w[4i+3]}      │
│          for i = 0 to 14                                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 Key Expansion Control Signals

| Signal | Width | Description |
|--------|-------|-------------|
| key_cnt | 6 bits | Current word index (0-59) |
| key_exp_active | 1 bit | High during key expansion |
| key_exp_done | 1 bit | High when all 60 words computed |
| rcon_sel | 4 bits | Select Rcon constant (1-10) |

### 4.3 Rcon Constants

```verilog
localparam [31:0] RCON [1:10] = '{
    32'h01000000,  // Rcon[1]
    32'h02000000,  // Rcon[2]
    32'h04000000,  // Rcon[3]
    32'h08000000,  // Rcon[4]
    32'h10000000,  // Rcon[5]
    32'h20000000,  // Rcon[6]
    32'h40000000,  // Rcon[7]
    32'h80000000,  // Rcon[8]
    32'h1B000000,  // Rcon[9]
    32'h36000000   // Rcon[10]
};
```

## 5. Encryption Round Datapath

### 5.1 aes_round Block Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           aes_round                                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Input:  state_in[127:0], round_key[127:0]                              │
│  Output: state_out[127:0]                                                │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  SubBytes (16 parallel S-Box lookups)                           │    │
│  │                                                                  │    │
│  │  s0 ──► S-Box ──► s0'                                           │    │
│  │  s1 ──► S-Box ──► s1'                                           │    │
│  │  ...                                                             │    │
│  │  s15 ──► S-Box ──► s15'                                         │    │
│  │                                                                  │    │
│  │  Output: sub_bytes_out[127:0]                                   │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                  │                                       │
│                                  ▼                                       │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  ShiftRows (byte permutation - no logic, just routing)          │    │
│  │                                                                  │    │
│  │  Input matrix:          Output matrix:                          │    │
│  │  ┌───┬───┬───┬───┐     ┌───┬───┬───┬───┐                       │    │
│  │  │s0 │s4 │s8 │s12│     │s0 │s4 │s8 │s12│  (no shift)          │    │
│  │  ├───┼───┼───┼───┤ ──► ├───┼───┼───┼───┤                       │    │
│  │  │s1 │s5 │s9 │s13│     │s5 │s9 │s13│s1 │  (shift 1)           │    │
│  │  ├───┼───┼───┼───┤     ├───┼───┼───┼───┤                       │    │
│  │  │s2 │s6 │s10│s14│     │s10│s14│s2 │s6 │  (shift 2)           │    │
│  │  ├───┼───┼───┼───┤     ├───┼───┼───┼───┤                       │    │
│  │  │s3 │s7 │s11│s15│     │s15│s3 │s7 │s11│  (shift 3)           │    │
│  │  └───┴───┴───┴───┘     └───┴───┴───┴───┘                       │    │
│  │                                                                  │    │
│  │  Output: shift_rows_out[127:0]                                  │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                  │                                       │
│                                  ▼                                       │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  MixColumns (4 parallel column mixers)                          │    │
│  │                                                                  │    │
│  │  For each column [a, b, c, d]:                                  │    │
│  │                                                                  │    │
│  │  a' = xtime(a) ^ xtime(b) ^ b ^ c ^ d                          │    │
│  │  b' = a ^ xtime(b) ^ xtime(c) ^ c ^ d                          │    │
│  │  c' = a ^ b ^ xtime(c) ^ xtime(d) ^ d                          │    │
│  │  d' = xtime(a) ^ a ^ b ^ c ^ xtime(d)                          │    │
│  │                                                                  │    │
│  │  Where xtime(x) = {x[6:0], 1'b0} ^ (x[7] ? 8'h1B : 8'h00)     │    │
│  │                                                                  │    │
│  │  Output: mix_columns_out[127:0]                                 │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                  │                                       │
│                                  ▼                                       │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  AddRoundKey (128-bit XOR)                                      │    │
│  │                                                                  │    │
│  │  state_out = mix_columns_out ^ round_key                        │    │
│  │                                                                  │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 5.2 xtime Function

```verilog
// GF(2^8) multiplication by 2
function [7:0] xtime;
    input [7:0] b;
    begin
        xtime = (b << 1) ^ (b[7] ? 8'h1B : 8'h00);
    end
endfunction
```

### 5.3 MixColumns Column Calculation

```verilog
// Single column mixing
module mix_column(
    input  [31:0] col_in,   // {a, b, c, d}
    output [31:0] col_out   // {a', b', c', d'}
);
    wire [7:0] a = col_in[31:24];
    wire [7:0] b = col_in[23:16];
    wire [7:0] c = col_in[15:8];
    wire [7:0] d = col_in[7:0];

    wire [7:0] a_x2 = xtime(a);
    wire [7:0] b_x2 = xtime(b);
    wire [7:0] c_x2 = xtime(c);
    wire [7:0] d_x2 = xtime(d);

    assign col_out[31:24] = a_x2 ^ b_x2 ^ b ^ c ^ d;        // a'
    assign col_out[23:16] = a ^ b_x2 ^ c_x2 ^ c ^ d;        // b'
    assign col_out[15:8]  = a ^ b ^ c_x2 ^ d_x2 ^ d;        // c'
    assign col_out[7:0]   = a_x2 ^ a ^ b ^ c ^ d_x2;        // d'
endmodule
```

## 6. Decryption Round Datapath

### 6.1 aes_inv_round Block Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          aes_inv_round                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Input:  state_in[127:0], round_key[127:0]                              │
│  Output: state_out[127:0]                                                │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  InvShiftRows (inverse byte permutation)                        │    │
│  │                                                                  │    │
│  │  Input matrix:          Output matrix:                          │    │
│  │  ┌───┬───┬───┬───┐     ┌───┬───┬───┬───┐                       │    │
│  │  │s0 │s4 │s8 │s12│     │s0 │s4 │s8 │s12│  (no shift)          │    │
│  │  ├───┼───┼───┼───┤ ──► ├───┼───┼───┼───┤                       │    │
│  │  │s1 │s5 │s9 │s13│     │s13│s1 │s5 │s9 │  (shift right 1)     │    │
│  │  ├───┼───┼───┼───┤     ├───┼───┼───┼───┤                       │    │
│  │  │s2 │s6 │s10│s14│     │s10│s14│s2 │s6 │  (shift right 2)     │    │
│  │  ├───┼───┼───┼───┤     ├───┼───┼───┼───┤                       │    │
│  │  │s3 │s7 │s11│s15│     │s7 │s11│s15│s3 │  (shift right 3)     │    │
│  │  └───┴───┴───┴───┘     └───┴───┴───┴───┘                       │    │
│  │                                                                  │    │
│  │  Output: inv_shift_rows_out[127:0]                              │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                  │                                       │
│                                  ▼                                       │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  InvSubBytes (16 parallel inverse S-Box lookups)                │    │
│  │                                                                  │    │
│  │  Output: inv_sub_bytes_out[127:0]                               │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                  │                                       │
│                                  ▼                                       │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  AddRoundKey (128-bit XOR)                                      │    │
│  │                                                                  │    │
│  │  Output: add_key_out[127:0]                                     │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                  │                                       │
│                                  ▼                                       │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  InvMixColumns (4 parallel inverse column mixers)               │    │
│  │                                                                  │    │
│  │  For each column [a, b, c, d]:                                  │    │
│  │                                                                  │    │
│  │  a' = mul14(a) ^ mul11(b) ^ mul13(c) ^ mul9(d)                 │    │
│  │  b' = mul9(a) ^ mul14(b) ^ mul11(c) ^ mul13(d)                 │    │
│  │  c' = mul13(a) ^ mul9(b) ^ mul14(c) ^ mul11(d)                 │    │
│  │  d' = mul11(a) ^ mul13(b) ^ mul9(c) ^ mul14(d)                 │    │
│  │                                                                  │    │
│  │  Where:                                                         │    │
│  │  mul9(x)  = xtime(xtime(xtime(x))) ^ x                          │    │
│  │  mul11(x) = xtime(xtime(xtime(x))) ^ xtime(x) ^ x              │    │
│  │  mul13(x) = xtime(xtime(xtime(x))) ^ xtime(xtime(x)) ^ x       │    │
│  │  mul14(x) = xtime(xtime(xtime(x))) ^ xtime(xtime(x)) ^ xtime(x)│    │
│  │                                                                  │    │
│  │  Output: state_out[127:0]                                       │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 6.2 Inverse Multiplication Functions

```verilog
// GF(2^8) multiplication by constants for InvMixColumns
function [7:0] mul9;
    input [7:0] x;
    begin
        mul9 = xtime(xtime(xtime(x))) ^ x;
    end
endfunction

function [7:0] mul11;
    input [7:0] x;
    begin
        mul11 = xtime(xtime(xtime(x))) ^ xtime(x) ^ x;
    end
endfunction

function [7:0] mul13;
    input [7:0] x;
    begin
        mul13 = xtime(xtime(xtime(x))) ^ xtime(xtime(x)) ^ x;
    end
endfunction

function [7:0] mul14;
    input [7:0] x;
    begin
        mul14 = xtime(xtime(xtime(x))) ^ xtime(xtime(x)) ^ xtime(x);
    end
endfunction
```

## 7. Control Signal Generation

### 7.1 Round Counter Logic

```verilog
// Round counter: 0-14
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        round_cnt <= 4'd0;
    else if (state == IDLE && start)
        round_cnt <= 4'd0;
    else if (state == BUSY && key_exp_done)
        round_cnt <= round_cnt + 4'd1;
end

// Round type detection
wire is_initial_round = (round_cnt == 4'd0);
wire is_final_round   = (round_cnt == 4'd14);
wire is_full_round    = !is_initial_round && !is_final_round;
```

### 7.2 Datapath Mux Select

```verilog
// Datapath selection
wire use_encrypt_path = (mode_reg == 1'b0);
wire use_decrypt_path = (mode_reg == 1'b1);

// Round key index
wire [3:0] round_key_idx = use_encrypt_path ? round_cnt : (4'd14 - round_cnt);

// State next value selection
reg [127:0] state_next;
always @(*) begin
    if (is_initial_round)
        state_next = add_round_key_out;  // Initial AddRoundKey only
    else if (use_encrypt_path)
        state_next = aes_round_out;
    else
        state_next = aes_inv_round_out;
end
```

## 8. Complete Cycle-by-Cycle Data Flow

### 8.1 Encryption Operation (16 cycles)

| Cycle | State | Operation | Data Flow |
|-------|-------|-----------|-----------|
| 0 | IDLE→BUSY | Load inputs, start key expansion | key_reg ← key, data_in_reg ← data_in, mode_reg ← mode |
| 1 | BUSY | Key expansion (words 8-15) | Compute w[8..15] |
| 2 | BUSY | Key expansion (words 16-23) | Compute w[16..23] |
| 3 | BUSY | Key expansion (words 24-31) | Compute w[24..31] |
| 4 | BUSY | Key expansion (words 32-39) | Compute w[32..39] |
| 5 | BUSY | Key expansion (words 40-47) | Compute w[40..47] |
| 6 | BUSY | Key expansion (words 48-55) | Compute w[48..55] |
| 7 | BUSY | Key expansion (words 56-59), Initial ARK | Compute w[56..59], state ← AddRoundKey(data_in, round_key[0]) |
| 8 | BUSY | Round 1 (Full) | state ← SubBytes(ShiftRows(MixColumns(AddRoundKey(state, round_key[1])))) |
| 9 | BUSY | Round 2 (Full) | state ← Round(state, round_key[2]) |
| 10 | BUSY | Round 3 (Full) | state ← Round(state, round_key[3]) |
| 11 | BUSY | Round 4 (Full) | state ← Round(state, round_key[4]) |
| 12 | BUSY | Round 5 (Full) | state ← Round(state, round_key[5]) |
| 13 | BUSY | Round 6 (Full) | state ← Round(state, round_key[6]) |
| 14 | BUSY | Round 7 (Full) | state ← Round(state, round_key[7]) |
| 15 | BUSY | Round 8 (Full) | state ← Round(state, round_key[8]) |
| 16 | BUSY | Round 9 (Full) | state ← Round(state, round_key[9]) |
| 17 | BUSY | Round 10 (Full) | state ← Round(state, round_key[10]) |
| 18 | BUSY | Round 11 (Full) | state ← Round(state, round_key[11]) |
| 19 | BUSY | Round 12 (Full) | state ← Round(state, round_key[12]) |
| 20 | BUSY | Round 13 (Full) | state ← Round(state, round_key[13]) |
| 21 | BUSY | Round 14 (Final) | state ← SubBytes(ShiftRows(AddRoundKey(state, round_key[14]))) |
| 22 | BUSY→IDLE | Output valid | data_out ← state, valid ← 1 |

**Note**: The spec mentions 16 cycles but with sequential key expansion, we need 8 cycles for key expansion + 14 rounds + 1 output = 23 cycles. We can optimize by overlapping key expansion with initial round.

### 8.2 Optimized Cycle Count

By computing key expansion in parallel with the initial rounds:

| Cycles | Activity |
|--------|----------|
| 0 | Load inputs |
| 1-7 | Key expansion (words 8-59) |
| 1 | Initial AddRoundKey (with round_key[0] = input key[255:128]) |
| 2-14 | Full rounds 1-13 |
| 15 | Final round 14 |
| 16 | Output valid |

**Total: 17 cycles** (or 16 if we pre-load round_key[0])

---

**Document Version**: 1.0
**Last Updated**: 2026-03-10
**Status**: Complete
