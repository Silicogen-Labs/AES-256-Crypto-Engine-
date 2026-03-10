# AES-256 Top-Level State Machine

## Architecture Overview

Iterative architecture with single round datapath reused across all 14 rounds.

**Latency**: 16 cycles per block
- Cycle 0: Load input, initial AddRoundKey
- Cycles 1–13: Full rounds (SubBytes, ShiftRows, MixColumns, AddRoundKey)
- Cycle 14: Final round (SubBytes, ShiftRows, AddRoundKey)
- Cycle 15: Output valid

## State Machine

```
                    ┌─────────────┐
        rst_n=0     │             │
    ┌──────────────►│    IDLE     │◄────────────────┐
    │               │             │                 │
    │               └──────┬──────┘                 │
    │                      │ start=1                │
    │                      ▼                        │
    │               ┌─────────────┐                 │
    │               │             │                 │
    └───────────────┤   BUSY      │─────────────────┘
                    │             │  round_cnt=14
                    └─────────────┘
```

## States

| State | Encoding | Description |
|-------|----------|-------------|
| IDLE | 2'b00 | Waiting for start command |
| BUSY | 2'b01 | Processing rounds |

## State Transitions

| Current | Condition | Next | Actions |
|---------|-----------|------|---------|
| IDLE | rst_n=0 | IDLE | Reset state |
| IDLE | start=1 | BUSY | Load data_in, key; round_cnt=0; busy=1 |
| BUSY | round_cnt<14 | BUSY | round_cnt++; process round |
| BUSY | round_cnt==14 | IDLE | valid=1; busy=0; output data_out |

## Control Signals

| Signal | Type | Description |
|--------|------|-------------|
| busy | output | High when processing |
| valid | output | Pulse high when data_out ready |
| round_cnt | internal | 4-bit counter (0–14) |

## Datapath Control

| Round | SubBytes | ShiftRows | MixColumns | AddRoundKey | KeySel |
|-------|----------|-----------|------------|-------------|--------|
| 0 | No | No | No | Yes | 0 |
| 1–13 | Yes | Yes | Yes | Yes | round_cnt |
| 14 | Yes | Yes | No | Yes | 14 |

## Key Schedule Control

Key expansion produces 15 round keys (0–14). Round key i is used in round i.

- Round 0: Initial AddRoundKey with round key 0
- Rounds 1–14: AddRoundKey with corresponding round key

## Interface Timing

```
Cycle:  0      1      2      ...   14     15     16
        ─────────────────────────────────────────────
start:  ▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
mode:   ════════════════════════ (constant)
key:    ════════════════════════ (constant)
data_in:════════════════════════ (constant)
busy:   ░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░
valid:  ░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░░░░░░░░░░
data_out:═══════════════════════════════▓▓▓▓▓▓▓▓▓▓▓▓
```

## Module Hierarchy

```
aes_top
├── aes_key_expansion (key schedule)
├── aes_round / aes_inv_round (round datapath)
│   ├── aes_sbox / aes_inv_sbox (16 instances)
│   ├── aes_shift_rows / aes_inv_shift_rows
│   ├── aes_mix_columns / aes_inv_mix_columns
│   └── aes_add_round_key
└── State register (128-bit)
```

## Implementation Notes

1. **S-Box**: Implemented as combinational case statement (256 entries)
2. **KeyExpansion**: Can be pre-computed or on-the-fly; this design uses on-the-fly
3. **Round key storage**: 15 × 128 bits = 1920 bits total
4. **State register**: 128 bits, updated each round
