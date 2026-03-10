# AES-256 Interface Specification

## 1. Overview

This document defines the complete interface specification for the AES-256 crypto engine, including top-level ports, internal module interfaces, and timing requirements.

## 2. Top-Level Interface (aes_top)

### 2.1 Port List

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| clk | Input | 1 | System clock |
| rst_n | Input | 1 | Active-low synchronous reset |
| start | Input | 1 | Pulse high for 1 cycle to begin |
| mode | Input | 1 | 0 = encrypt, 1 = decrypt |
| key | Input | 256 | AES-256 key |
| data_in | Input | 128 | Plaintext (encrypt) or ciphertext (decrypt) |
| data_out | Output | 128 | Ciphertext (encrypt) or plaintext (decrypt) |
| valid | Output | 1 | data_out is valid (1 cycle pulse) |
| busy | Output | 1 | Engine is processing |

### 2.2 Port Timing Requirements

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           TIMING DIAGRAM                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Clock:    ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐     │
│            │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │     │
│         ───┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──   │
│                                                                              │
│  rst_n:   ░░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
│                                                                              │
│  start:   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│                     │                  │                                     │
│  key:     ══════════════════════════════════════════════════════════════════│
│                     │                  │                                     │
│  data_in: ══════════════════════════════════════════════════════════════════│
│                     │                  │                                     │
│  mode:    ══════════════════════════════════════════════════════════════════│
│                     │                  │                                     │
│  busy:    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
│                     │                  │                                     │
│  valid:   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓░│
│                     │                  │                                     │
│  data_out:════════════════════════════════════════════════════════════════▓▓▓│
│                     │                  │                                     │
│                     │                  │                                     │
│  Cycle:   -4  -3  -2  -1   0   1   2   3   4   5  ...  16  17  18  19      │
│                     │                  │                                     │
│  Phase:   Reset     │   IDLE    BUSY (processing)      IDLE                │
│                     │                  │                                     │
│  Setup:   key, data_in, mode must be stable before start rising edge        │
│  Hold:    key, data_in, mode must remain stable until busy rises            │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.3 Interface Protocol

#### 2.3.1 Start Transaction

1. **Setup phase**: Drive `key[255:0]`, `data_in[127:0]`, and `mode` stable
2. **Start pulse**: Assert `start` for exactly 1 clock cycle
3. **Busy phase**: `busy` goes high on next cycle; hold inputs until `busy` rises
4. **Processing**: Engine processes for 16 cycles
5. **Completion**: `valid` pulses high for 1 cycle; `data_out` contains result
6. **Next transaction**: Can start new operation on cycle after `valid`

#### 2.3.2 Back-to-Back Transactions

```
Cycle:    0   1   2  ...  15  16  17  18  19  ...  32  33
          │   │   │      │   │   │   │   │      │   │
start:    ▓▓▓░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░░░░░
          │   │   │      │   │   │   │   │      │   │
busy:     ░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
          │   │   │      │   │   │   │   │      │   │
valid:    ░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░░░▓▓▓░
          │   │   │      │   │   │   │   │      │   │
data_out: ════════════════════════▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
          │   │   │      │   │   │   │   │      │   │
          │   │   │      │   │   │   │   │      │   │
          │   │   │      └───┘   │   │   │      │   │
          │   │   │   Result 1   │   │   │      │   │
          │   │   │              └───┘   │      │   │
          │   │   │           Result 2   │      │   │
          │   │   │                      │      │   │
Gap between transactions: 0 cycles (can start immediately after valid)
```

### 2.4 Signal Detailed Specifications

#### 2.4.1 clk (Clock)

| Parameter | Specification |
|-----------|---------------|
| Frequency | 50 MHz (nominal) |
| Duty cycle | 50% ± 10% |
| Jitter | < 100 ps |
| Source | External system clock |

#### 2.4.2 rst_n (Reset)

| Parameter | Specification |
|-----------|---------------|
| Polarity | Active-low |
| Type | Synchronous |
| Minimum pulse | 2 clock cycles |
| Recovery time | 1 clock cycle |
| Effect | Clears all state, returns to IDLE |

#### 2.4.3 start (Start Command)

| Parameter | Specification |
|-----------|---------------|
| Width | 1 bit |
| Polarity | Active-high |
| Duration | Exactly 1 clock cycle |
| Setup time | 2 ns before rising clk edge |
| Hold time | 0 ns after rising clk edge |
| Effect | Begins encryption/decryption operation |

#### 2.4.4 mode (Operation Mode)

| Value | Meaning |
|-------|---------|
| 0 | Encryption |
| 1 | Decryption |

| Parameter | Specification |
|-----------|---------------|
| Width | 1 bit |
| Sampling | Latched on rising edge of start |
| Stability | Must be stable 2 ns before start rising edge |

#### 2.4.5 key (AES Key)

| Parameter | Specification |
|-----------|---------------|
| Width | 256 bits |
| Byte order | Big-endian (byte 0 = key[255:248]) |
| Sampling | Latched on rising edge of start |
| Stability | Must be stable 2 ns before start rising edge |

Byte mapping:
```
key[255:248] = byte 0 (most significant)
key[247:240] = byte 1
...
key[15:8]    = byte 30
key[7:0]     = byte 31 (least significant)
```

#### 2.4.6 data_in (Input Data)

| Parameter | Specification |
|-----------|---------------|
| Width | 128 bits |
| Byte order | Big-endian |
| Sampling | Latched on rising edge of start |
| Stability | Must be stable 2 ns before start rising edge |

For encryption: plaintext
For decryption: ciphertext

#### 2.4.7 data_out (Output Data)

| Parameter | Specification |
|-----------|---------------|
| Width | 128 bits |
| Byte order | Big-endian |
| Validity | Valid when valid=1 |
| Hold time | Valid for 1 cycle after valid pulse |

For encryption: ciphertext
For decryption: plaintext

#### 2.4.8 valid (Output Valid)

| Parameter | Specification |
|-----------|---------------|
| Width | 1 bit |
| Polarity | Active-high |
| Duration | Exactly 1 clock cycle |
| Timing | Asserted 16 cycles after start |
| Meaning | data_out contains valid result |

#### 2.4.9 busy (Busy Indicator)

| Parameter | Specification |
|-----------|---------------|
| Width | 1 bit |
| Polarity | Active-high |
| Timing | Asserted 1 cycle after start, cleared when valid asserted |
| Meaning | Engine is processing; ignore start pulses |

## 3. Internal Module Interfaces

### 3.1 aes_key_expansion

```verilog
module aes_key_expansion (
    input              clk,
    input              rst_n,
    input              start,
    input      [255:0] key_in,
    output reg [1919:0] round_keys,  // 15 round keys × 128 bits
    output             done
);
```

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| clk | Input | 1 | Clock |
| rst_n | Input | 1 | Reset |
| start | Input | 1 | Begin expansion |
| key_in | Input | 256 | Input key |
| round_keys | Output | 1920 | All expanded round keys |
| done | Output | 1 | Expansion complete |

### 3.2 aes_round (Encryption Round)

```verilog
module aes_round (
    input  [127:0] state_in,
    input  [127:0] round_key,
    input          is_final,      // 1 = final round (no MixColumns)
    output [127:0] state_out
);
```

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| state_in | Input | 128 | Input state |
| round_key | Input | 128 | Round key for AddRoundKey |
| is_final | Input | 1 | Final round flag (skip MixColumns) |
| state_out | Output | 128 | Output state |

### 3.3 aes_inv_round (Decryption Round)

```verilog
module aes_inv_round (
    input  [127:0] state_in,
    input  [127:0] round_key,
    input          is_final,      // 1 = final round (no InvMixColumns)
    output [127:0] state_out
);
```

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| state_in | Input | 128 | Input state |
| round_key | Input | 128 | Round key for AddRoundKey |
| is_final | Input | 1 | Final round flag |
| state_out | Output | 128 | Output state |

### 3.4 aes_sbox (S-Box Lookup)

```verilog
module aes_sbox (
    input  [7:0] data_in,
    output [7:0] data_out
);
```

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| data_in | Input | 8 | Input byte |
| data_out | Output | 8 | Substituted byte |

### 3.5 aes_inv_sbox (Inverse S-Box)

```verilog
module aes_inv_sbox (
    input  [7:0] data_in,
    output [7:0] data_out
);
```

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| data_in | Input | 8 | Input byte |
| data_out | Output | 8 | Inverse substituted byte |

### 3.6 aes_shift_rows

```verilog
module aes_shift_rows (
    input  [127:0] data_in,
    output [127:0] data_out
);
```

Purely combinational - byte permutation only.

### 3.7 aes_inv_shift_rows

```verilog
module aes_inv_shift_rows (
    input  [127:0] data_in,
    output [127:0] data_out
);
```

Purely combinational - byte permutation only.

### 3.8 aes_mix_columns

```verilog
module aes_mix_columns (
    input  [127:0] data_in,
    output [127:0] data_out
);
```

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| data_in | Input | 128 | Input state |
| data_out | Output | 128 | Mixed columns |

### 3.9 aes_inv_mix_columns

```verilog
module aes_inv_mix_columns (
    input  [127:0] data_in,
    output [127:0] data_out
);
```

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| data_in | Input | 128 | Input state |
| data_out | Output | 128 | Inverse mixed columns |

### 3.10 aes_add_round_key

```verilog
module aes_add_round_key (
    input  [127:0] data_in,
    input  [127:0] round_key,
    output [127:0] data_out
);
```

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| data_in | Input | 128 | Input state |
| round_key | Input | 128 | Round key |
| data_out | Output | 128 | XOR result |

## 4. Data Format Specifications

### 4.1 Key Format (256-bit)

```
Key word 0: key[255:224] = {byte0, byte1, byte2, byte3}
Key word 1: key[223:192] = {byte4, byte5, byte6, byte7}
...
Key word 7: key[31:0]    = {byte28, byte29, byte30, byte31}
```

NIST test vector example:
```
Key = 00010203 04050607 08090a0b 0c0d0e0f 10111213 14151617 18191a1b 1c1d1e1f

key[255:224] = 32'h00010203
key[223:192] = 32'h04050607
...
key[31:0]    = 32'h1c1d1e1f
```

### 4.2 Data Format (128-bit)

```
Input:  data_in[127:0] = {col3, col2, col1, col0}

Where:
col0 = data_in[31:0]   = {s0, s1, s2, s3}
col1 = data_in[63:32]  = {s4, s5, s6, s7}
col2 = data_in[95:64]  = {s8, s9, s10, s11}
col3 = data_in[127:96] = {s12, s13, s14, s15}
```

NIST test vector example:
```
Plaintext = 00112233 44556677 8899aabb ccddeeff

data_in[127:96] = 32'h00112233
data_in[95:64]  = 32'h44556677
data_in[63:32]  = 32'h8899aabb
data_in[31:0]   = 32'hccddeeff
```

### 4.3 State Matrix Mapping

```
State matrix (4×4 bytes):
        Col 0   Col 1   Col 2   Col 3
       ┌───────┬───────┬───────┬───────┐
Row 0  │ s0    │ s4    │ s8    │ s12   │
       ├───────┼───────┼───────┼───────┤
Row 1  │ s1    │ s5    │ s9    │ s13   │
       ├───────┼───────┼───────┼───────┤
Row 2  │ s2    │ s6    │ s10   │ s14   │
       ├───────┼───────┼───────┼───────┤
Row 3  │ s3    │ s7    │ s11   │ s15   │
       └───────┴───────┴───────┴───────┘

Storage (column-major):
state[31:0]   = {s0, s1, s2, s3}     // Column 0
state[63:32]  = {s4, s5, s6, s7}     // Column 1
state[95:64]  = {s8, s9, s10, s11}   // Column 2
state[127:96] = {s12, s13, s14, s15} // Column 3
```

## 5. Timing Constraints

### 5.1 Clock Constraints

```sdc
# Clock definition
create_clock -name clk -period 20.0 [get_ports clk]

# Clock uncertainty
set_clock_uncertainty 0.5 [get_clocks clk]

# Clock transition
set_clock_transition 0.2 [get_clocks clk]
```

### 5.2 Input Constraints

```sdc
# Input delay (2 ns)
set_input_delay -clock clk 2.0 [get_ports {start mode key data_in}]

# Input transition
set_input_transition 0.2 [get_ports {start mode key data_in}]
```

### 5.3 Output Constraints

```sdc
# Output delay (2 ns)
set_output_delay -clock clk 2.0 [get_ports {data_out valid busy}]

# Output load (50 fF)
set_output_load 50.0 [get_ports {data_out valid busy}]
```

### 5.4 False Paths

```sdc
# None - all paths are synchronous
```

## 6. Power-Up and Reset Behavior

### 6.1 Power-Up Sequence

1. Apply power
2. Apply stable clock
3. Assert rst_n for minimum 2 cycles
4. Release rst_n
5. Module is ready (IDLE state)

### 6.2 Reset Behavior

| Element | Reset Value |
|---------|-------------|
| State register | All zeros |
| Round keys | All zeros |
| Round counter | 0 |
| Key counter | 0 |
| FSM state | IDLE |
| busy | 0 |
| valid | 0 |

## 7. Error Handling

### 7.1 Invalid Start During Busy

If `start` is asserted while `busy` is high, it is ignored.

### 7.2 Glitch Filtering

`start` must be high for exactly 1 cycle. If held longer, subsequent cycles are ignored.

### 7.3 Mode Change During Operation

`mode` is latched on `start` rising edge. Changes during operation are ignored.

---

**Document Version**: 1.0
**Last Updated**: 2026-03-10
**Status**: Complete
