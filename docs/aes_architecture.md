# AES-256 Crypto Engine Architecture

## Overview

Iterative AES-256 implementation with 16 cycles per block (1 initial + 14 rounds).

## Datapath

```
                    Key (256-bit)
                       │
                       ▼
              ┌─────────────────┐
              │  Key Expansion  │◄── Round index (0-14)
              │   (on-the-fly)  │
              └────────┬────────┘
                       │ RoundKey (128-bit)
                       ▼
DataIn (128) ──►┌─────────────┐──► DataOut (128)
                │   AES Core  │
                │  (14 rounds)│
                │   iterative │
                └─────────────┘
                       ▲
                       │ Mode (enc/dec)
```

### State Register

- 128-bit register holds current state
- Updated each cycle with round output

### Round Datapath

```
State (128) ──► AddRoundKey ──► SubBytes ──► ShiftRows ──► MixColumns ──► Next State
                      ▲                                              │
                      │                                              │
                 RoundKey                                            │
              (from key expansion)                                   │
                                                                     │
              Final round: no MixColumns ◄───────────────────────────┘
```

## State Machine

```
                    ┌─────────┐
         rst_n ────►│  IDLE   │◄────────────────────────────┐
                    └────┬────┘                             │
                         │ start=1                           │
                         ▼                                   │
                    ┌─────────┐     ┌─────────┐     ┌─────────┐
         ┌─────────►│  LOAD   │────►│ ADD_RK0 │────►│ ROUND   │──┐
         │          │ (cycle0)│     │ (cycle1)│     │  1-13   │  │
         │          └─────────┘     └─────────┘     └────┬────┘  │
         │                                               │       │
         │                                               │       │
         │          ┌─────────┐     ┌─────────┐          │       │
         │          │  DONE   │◄────│ FINAL   │◄─────────┘       │
         │          │(cycle16)│     │(cycle15)│                  │
         │          └────┬────┘     └─────────┘                  │
         │               │ valid=1                               │
         │               ▼                                        │
         └───────────────┘              (14 rounds × 1 cycle each)│
```

### State Encoding

| State | Encoding | Description |
|-------|----------|-------------|
| IDLE | 3'b000 | Waiting for start |
| LOAD | 3'b001 | Load input data |
| ADD_RK0 | 3'b010 | Initial AddRoundKey (round 0) |
| ROUND | 3'b011 | Full rounds 1-13 |
| FINAL | 3'b100 | Final round (no MixColumns) |
| DONE | 3'b101 | Output valid |

### State Transitions

| Current | Condition | Next | Actions |
|---------|-----------|------|---------|
| IDLE | start=1 | LOAD | Load data_in to state_reg |
| LOAD | always | ADD_RK0 | AddRoundKey with w[0..3] |
| ADD_RK0 | always | ROUND | round_cnt=1, SubBytes→ShiftRows→MixColumns→ARK |
| ROUND | round_cnt<13 | ROUND | round_cnt++, continue rounds |
| ROUND | round_cnt=13 | FINAL | round_cnt=14, no MixColumns |
| FINAL | always | DONE | Output result, set valid |
| DONE | always | IDLE | Clear busy, await next start |

## Control Signals

| Signal | Width | Source | Description |
|--------|-------|--------|-------------|
| state | 3 | FSM | Current state |
| round_cnt | 4 | Counter | 0-14 round counter |
| key_word_sel | 2 | Control | Select 32-bit word from key schedule |
| subbytes_en | 1 | Control | Enable SubBytes transformation |
| shiftrows_en | 1 | Control | Enable ShiftRows transformation |
| mixcolumns_en | 1 | Control | Enable MixColumns (0 for final round) |
| addroundkey_en | 1 | Control | Enable AddRoundKey |
| state_load | 1 | Control | Load new data to state register |
| valid | 1 | FSM | Output data valid |
| busy | 1 | FSM | Processing in progress |

## Key Schedule

### On-the-fly Expansion

For iterative architecture, generate round keys as needed:

```
Round 0:  w[0..3]   (first 128 bits of input key)
Round 1:  w[4..7]   (second 128 bits of input key)
Round 2+: computed via KeyExpansion
```

### KeyExpansion Logic

For i = 8 to 59 (word indices):
- temp = w[i-1]
- If i mod 8 == 0: temp = SubWord(RotWord(temp)) XOR Rcon[i/8]
- If i mod 8 == 4: temp = SubWord(temp)  (AES-256 only)
- w[i] = w[i-8] XOR temp

### Rcon Values

| i | Rcon[i] |
|---|---------|
| 1 | 0x01 |
| 2 | 0x02 |
| 3 | 0x04 |
| 4 | 0x08 |
| 5 | 0x10 |
| 6 | 0x20 |
| 7 | 0x40 |

## Module Hierarchy

```
aes_top
├── aes_key_expansion
│   └── aes_sbox (for SubWord)
├── aes_round
│   ├── aes_add_round_key
│   ├── aes_sub_bytes
│   │   └── aes_sbox (×16 parallel)
│   ├── aes_shift_rows
│   └── aes_mix_columns
│       └── aes_mix_single_column (×4)
├── aes_inv_round (for decryption)
│   ├── aes_add_round_key
│   ├── aes_inv_shift_rows
│   ├── aes_inv_sub_bytes
│   │   └── aes_inv_sbox (×16)
│   └── aes_inv_mix_columns
│       └── aes_inv_mix_single_column (×4)
└── FSM + State Register + Control Logic
```

## Timing

| Cycle | Operation | Description |
|-------|-----------|-------------|
| 0 | LOAD | Load data_in, set busy |
| 1 | ADD_RK0 | Initial AddRoundKey (round 0) |
| 2-14 | ROUNDS 1-13 | Full rounds with MixColumns |
| 15 | FINAL | Round 14, no MixColumns |
| 16 | DONE | Output valid, clear busy |

Total: 16 cycles per 128-bit block

## Interface Signals

| Signal | Dir | Width | Description |
|--------|-----|-------|-------------|
| clk | I | 1 | Clock |
| rst_n | I | 1 | Active-low reset |
| start | I | 1 | Start operation |
| mode | I | 1 | 0=encrypt, 1=decrypt |
| key | I | 256 | AES-256 key |
| data_in | I | 128 | Input block |
| data_out | O | 128 | Output block |
| valid | O | 1 | Output valid |
| busy | O | 1 | Processing |

## NIST Test Vector

```
Key:        000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f
Plaintext:  00112233445566778899aabbccddeeff
Ciphertext: 8ea2b7ca516745bfeafc49904b496089
```
