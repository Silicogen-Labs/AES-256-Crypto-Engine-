# AES-256 Control Signals Specification

## 1. Overview

This document defines all control signals in the AES-256 design, their encoding, generation logic, and timing.

## 2. FSM State Encoding

### 2.1 State Definitions

| State | Encoding | Description |
|-------|----------|-------------|
| IDLE | 2'b00 | Waiting for start command |
| BUSY | 2'b01 | Processing key expansion and rounds |

### 2.2 State Transition Diagram

```
                    ┌─────────────────────────────────────────────┐
                    │                                             │
                    │                    IDLE                     │
                    │                                             │
                    │  ┌─────────────────────────────────────┐   │
        rst_n=0     │  │ Outputs:                            │   │
    ┌──────────────►│  │   busy = 0                          │   │
    │               │  │   valid = 0                         │   │
    │               │  │   round_cnt = 0                     │   │
    │               │  └─────────────────────────────────────┘   │
    │               │                     │                      │
    │               │                     │ start = 1            │
    │               │                     ▼                      │
    │               │  ┌─────────────────────────────────────┐   │
    │               │  │                                     │   │
    └───────────────┼──┤                BUSY                 │   │
                    │  │                                     │   │
                    │  │  ┌─────────────────────────────┐   │   │
                    │  │  │ Key expansion: cycles 1-7   │   │   │
                    │  │  │ Rounds 0-14: cycles 8-22    │   │   │
                    │  │  │ Output: cycle 23            │   │   │
                    │  │  └─────────────────────────────┘   │   │
                    │  │                                     │   │
                    │  │  Transition: round_cnt == 14      │   │
                    │  │  and operation complete           │   │
                    │  │                                     │   │
                    │  └─────────────────────────────────────┘   │
                    │                                             │
                    └─────────────────────────────────────────────┘
```

### 2.3 State Transition Table

| Current State | Condition | Next State | Actions |
|---------------|-----------|------------|---------|
| IDLE | rst_n = 0 | IDLE | Reset all counters and flags |
| IDLE | start = 1 | BUSY | Load inputs, begin key expansion |
| BUSY | round_cnt < 14 | BUSY | Continue processing |
| BUSY | round_cnt == 14 | IDLE | Assert valid, output result |

## 3. Control Signal Definitions

### 3.1 Global Control Signals

| Signal | Width | Direction | Description |
|--------|-------|-----------|-------------|
| clk | 1 | Input | System clock (50 MHz target) |
| rst_n | 1 | Input | Active-low synchronous reset |

### 3.2 Interface Control Signals

| Signal | Width | Direction | Description |
|--------|-------|-----------|-------------|
| start | 1 | Input | Pulse high for 1 cycle to begin operation |
| mode | 1 | Input | 0 = encrypt, 1 = decrypt |
| busy | 1 | Output | High when processing (ignore start) |
| valid | 1 | Output | Pulse high when data_out is valid |

### 3.3 Internal Control Signals

| Signal | Width | Description |
|--------|-------|-------------|
| state | 2 | FSM state (IDLE=2'b00, BUSY=2'b01) |
| round_cnt | 4 | Current round (0-14) |
| key_cnt | 6 | Key expansion word counter (0-59) |
| mode_reg | 1 | Latched mode value |
| key_exp_active | 1 | High during key expansion phase |
| key_exp_done | 1 | High when all 60 key words computed |

## 4. Control Signal Truth Tables

### 4.1 Round Type Detection

| round_cnt | is_initial | is_full | is_final | do_subbytes | do_shiftrows | do_mixcolumns |
|-----------|------------|---------|----------|-------------|--------------|---------------|
| 0 | 1 | 0 | 0 | 0 | 0 | 0 |
| 1-13 | 0 | 1 | 0 | 1 | 1 | 1 |
| 14 | 0 | 0 | 1 | 1 | 1 | 0 |

### 4.2 Datapath Control by Round Type

| Signal | Initial Round | Full Round | Final Round |
|--------|---------------|------------|-------------|
| sel_initial | 1 | 0 | 0 |
| sel_full | 0 | 1 | 0 |
| sel_final | 0 | 0 | 1 |
| en_subbytes | 0 | 1 | 1 |
| en_shiftrows | 0 | 1 | 1 |
| en_mixcolumns | 0 | 1 | 0 |
| en_addroundkey | 1 | 1 | 1 |

### 4.3 Encryption vs Decryption Control

| Signal | Encrypt (mode=0) | Decrypt (mode=1) |
|--------|------------------|------------------|
| sel_encrypt_path | 1 | 0 |
| sel_decrypt_path | 0 | 1 |
| round_key_idx | round_cnt | 14 - round_cnt |
| subbytes_select | aes_sbox | aes_inv_sbox |
| shiftrows_select | aes_shift_rows | aes_inv_shift_rows |
| mixcolumns_select | aes_mix_columns | aes_inv_mix_columns |

### 4.4 Complete Control Signal Table by Cycle

#### Encryption Operation

| Cycle | State | round_cnt | Key Exp | Operation | busy | valid |
|-------|-------|-----------|---------|-----------|------|-------|
| 0 | IDLE→BUSY | 0 | Start | Load inputs | 1→0 | 0 |
| 1 | BUSY | 0 | w[8-15] | Initial ARK | 1 | 0 |
| 2 | BUSY | 1 | w[16-23] | Round 1 | 1 | 0 |
| 3 | BUSY | 2 | w[24-31] | Round 2 | 1 | 0 |
| 4 | BUSY | 3 | w[32-39] | Round 3 | 1 | 0 |
| 5 | BUSY | 4 | w[40-47] | Round 4 | 1 | 0 |
| 6 | BUSY | 5 | w[48-55] | Round 5 | 1 | 0 |
| 7 | BUSY | 6 | w[56-59] | Round 6 | 1 | 0 |
| 8 | BUSY | 7 | Done | Round 7 | 1 | 0 |
| 9 | BUSY | 8 | - | Round 8 | 1 | 0 |
| 10 | BUSY | 9 | - | Round 9 | 1 | 0 |
| 11 | BUSY | 10 | - | Round 10 | 1 | 0 |
| 12 | BUSY | 11 | - | Round 11 | 1 | 0 |
| 13 | BUSY | 12 | - | Round 12 | 1 | 0 |
| 14 | BUSY | 13 | - | Round 13 | 1 | 0 |
| 15 | BUSY | 14 | - | Final Round | 1 | 0 |
| 16 | BUSY→IDLE | - | - | Output | 0→1 | 1 |

## 5. Control Logic Implementation

### 5.1 FSM Implementation

```verilog
// State encoding
localparam IDLE = 2'b00;
localparam BUSY = 2'b01;

reg [1:0] state_reg, state_next;

// State register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        state_reg <= IDLE;
    else
        state_reg <= state_next;
end

// Next state logic
always @(*) begin
    case (state_reg)
        IDLE: begin
            if (start)
                state_next = BUSY;
            else
                state_next = IDLE;
        end
        BUSY: begin
            if (round_cnt == 4'd14 && key_exp_done)
                state_next = IDLE;
            else
                state_next = BUSY;
        end
        default: state_next = IDLE;
    endcase
end
```

### 5.2 Round Counter

```verilog
reg [3:0] round_cnt;
wire round_cnt_en;

assign round_cnt_en = (state_reg == BUSY) && key_exp_done;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        round_cnt <= 4'd0;
    else if (state_reg == IDLE && start)
        round_cnt <= 4'd0;
    else if (round_cnt_en)
        round_cnt <= round_cnt + 4'd1;
end
```

### 5.3 Key Expansion Counter

```verilog
reg [5:0] key_cnt;
wire key_cnt_en;
wire key_exp_done;

assign key_cnt_en = (state_reg == BUSY) && (key_cnt < 6'd60);
assign key_exp_done = (key_cnt == 6'd60);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        key_cnt <= 6'd0;
    else if (state_reg == IDLE)
        key_cnt <= 6'd0;
    else if (key_cnt_en)
        key_cnt <= key_cnt + 6'd1;
end
```

### 5.4 Output Control Signals

```verilog
// busy output
assign busy = (state_reg == BUSY);

// valid output (single cycle pulse)
reg valid_reg;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        valid_reg <= 1'b0;
    else
        valid_reg <= (state_reg == BUSY) && (round_cnt == 4'd14) && key_exp_done;
end
assign valid = valid_reg;
```

### 5.5 Mode Register

```verilog
reg mode_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        mode_reg <= 1'b0;
    else if (state_reg == IDLE && start)
        mode_reg <= mode;
end
```

## 6. Datapath Control Generation

### 6.1 Round Type Signals

```verilog
wire is_initial_round = (round_cnt == 4'd0);
wire is_final_round   = (round_cnt == 4'd14);
wire is_full_round    = !is_initial_round && !is_final_round;

wire do_subbytes   = is_full_round || is_final_round;
wire do_shiftrows  = is_full_round || is_final_round;
wire do_mixcolumns = is_full_round;
wire do_addroundkey = 1'b1;  // Always
```

### 6.2 Path Selection

```verilog
wire use_encrypt_path = (mode_reg == 1'b0);
wire use_decrypt_path = (mode_reg == 1'b1);

wire [3:0] round_key_idx = use_encrypt_path ? round_cnt : (4'd14 - round_cnt);
```

### 6.3 State Next Mux Control

```verilog
reg [127:0] state_next;

always @(*) begin
    if (is_initial_round)
        state_next = add_round_key_result;
    else if (use_encrypt_path)
        state_next = aes_round_result;
    else
        state_next = aes_inv_round_result;
end
```

## 7. Timing Diagrams

### 7.1 Complete Encryption Timing

```
Clock:    ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐
          │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │
       ───┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──

          │     │     │     │     │     │     │     │     │     │
start:    ▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
          │     │     │     │     │     │     │     │     │     │
key:      ═══════════════════════════════════════════════════════════════════
          │     │     │     │     │     │     │     │     │     │
data_in:  ═══════════════════════════════════════════════════════════════════
          │     │     │     │     │     │     │     │     │     │
mode:     ═══════════════════════════════════════════════════════════════════
          │     │     │     │     │     │     │     │     │     │
busy:     ░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
          │     │     │     │     │     │     │     │     │     │
round_cnt: 0     0     1     2     3     4     5     6     7     8     ...
          │     │     │     │     │     │     │     │     │     │
key_cnt:   0     8     16    24    32    40    48    56    60    60
          │     │     │     │     │     │     │     │     │     │
state:    Load  Init  R1    R2    R3    R4    R5    R6    R7    R8
          │     │     │     │     │     │     │     │     │     │
valid:    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓░░
          │     │     │     │     │     │     │     │     │     │
data_out: ═══════════════════════════════════════════════════════════════▓▓▓▓▓
          │     │     │     │     │     │     │     │     │     │
          │     │     │     │     │     │     │     │     │     │
Legend:   ▓ = High/active    ░ = Low/inactive    ═ = Data valid
```

### 7.2 Reset Behavior

```
Clock:    ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐
          │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │
       ───┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──

          │     │     │     │     │     │     │
rst_n:    ░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
          │     │     │     │     │     │     │
state:    X     IDLE  IDLE  IDLE  IDLE  IDLE  IDLE
          │     │     │     │     │     │     │
round_cnt: X     0     0     0     0     0     0
          │     │     │     │     │     │     │
key_cnt:   X     0     0     0     0     0     0
          │     │     │     │     │     │     │
busy:     X     0     0     0     0     0     0
          │     │     │     │     │     │     │
valid:    X     0     0     0     0     0     0

Legend:   X = Unknown/undefined
```

## 8. Control Signal Summary Table

| Signal | Width | Source | Destination | Purpose |
|--------|-------|--------|-------------|---------|
| clk | 1 | Top input | All registers | System clock |
| rst_n | 1 | Top input | All registers | Active-low reset |
| start | 1 | Top input | FSM | Begin operation |
| mode | 1 | Top input | Mode reg | Encrypt/decrypt select |
| busy | 1 | FSM | Top output | Processing indicator |
| valid | 1 | FSM | Top output | Output valid pulse |
| state | 2 | FSM | Control logic | Current FSM state |
| round_cnt | 4 | Counter | Control logic | Round index |
| key_cnt | 6 | Counter | Key expansion | Key word index |
| mode_reg | 1 | Register | Control logic | Latched mode |
| key_exp_done | 1 | Comparator | FSM, Counter | Key expansion complete |
| is_initial_round | 1 | Comparator | Datapath mux | Initial round detect |
| is_final_round | 1 | Comparator | Datapath mux | Final round detect |
| use_encrypt_path | 1 | Mode reg | Datapath mux | Encrypt path select |
| round_key_idx | 4 | Subtractor | Key storage | Round key index |

---

**Document Version**: 1.0
**Last Updated**: 2026-03-10
**Status**: Complete
