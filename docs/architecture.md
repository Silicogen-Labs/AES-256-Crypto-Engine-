# AES-256 Architecture Document

## 1. Overview

This document describes the complete microarchitecture of the AES-256 cryptographic engine. The design follows an iterative (area-optimized) architecture where a single round datapath is reused across all 14 rounds.

### Key Characteristics

| Parameter | Value |
|-----------|-------|
| Algorithm | AES-256 (NIST FIPS-197) |
| Block size | 128 bits |
| Key size | 256 bits |
| Rounds | 14 |
| Architecture | Iterative (single round datapath) |
| Latency | 16 cycles per block |
| Throughput | ~400 MB/s @ 50 MHz |
| Target area | < 20,000 equivalent gates |
| Target frequency | 50 MHz (sky130 PDK) |

## 2. Block Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              aes_top                                         │
│                                                                              │
│  ┌─────────────┐    ┌─────────────────────────────────────────────────────┐  │
│  │   Control   │    │              Datapath                               │  │
│  │     FSM     │    │                                                     │  │
│  │             │    │  ┌──────────────┐      ┌──────────────────────┐    │  │
│  │  ┌───────┐  │    │  │   Key Exp    │      │    State Register    │    │  │
│  │  │ IDLE  │  │    │  │              │      │   (128 bits = 4×32)  │    │  │
│  │  └───┬───┘  │    │  │ w[0..59]     │      │                      │    │  │
│  │      │      │    │  │ 1920 bits    │      │  col0 │ col1 │ col2 │ col3│  │
│  │  ┌───▼───┐  │    │  │              │      │  [31:0][63:32][95:64][127:96]│  │
│  │  │ BUSY  │  │    │  └──────┬───────┘      └──────────┬───────────┘    │  │
│  │  └───┬───┘  │    │         │                         │                │  │
│  │      │      │    │    round_key[i]              state_out            │  │
│  │  round_cnt  │    │         │                         │                │  │
│  │  key_cnt    │    │         ▼                         ▼                │  │
│  │  busy       │    │  ┌─────────────────────────────────────────────┐   │  │
│  │  valid      │    │  │              Round Mux                      │   │  │
│  └─────────────┘    │  │  ┌─────────┐    ┌─────────┐                 │   │  │
│                     │  │  │  mode=0 │    │  mode=1 │                 │   │  │
│                     │  │  │ encrypt │    │ decrypt │                 │   │  │
│                     │  │  └───┬─────┘    └────┬────┘                 │   │  │
│                     │  │      │               │                      │   │  │
│                     │  │      ▼               ▼                      │   │  │
│                     │  │  ┌─────────┐    ┌─────────┐                 │   │  │
│                     │  │  │aes_round│    │aes_inv_ │                 │   │  │
│                     │  │  │         │    │ round   │                 │   │  │
│                     │  │  │SubBytes │    │InvSubB. │                 │   │  │
│                     │  │  │ShiftRows│    │InvShift │                 │   │  │
│                     │  │  │MixCols  │    │InvMixC. │                 │   │  │
│                     │  │  │AddRK    │    │AddRK    │                 │   │  │
│                     │  │  └────┬────┘    └────┬────┘                 │   │  │
│                     │  │       │              │                       │   │  │
│                     │  │       └──────┬───────┘                       │   │  │
│                     │  │              │                               │   │  │
│                     │  └──────────────┼───────────────────────────────┘   │  │
│                     │                 │                                   │  │
│                     │                 ▼                                   │  │
│                     │         state_next (feedback)                       │  │
│                     │                                                     │  │
│                     └─────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 3. Module Hierarchy

```
aes_top
├── Control Logic
│   ├── FSM (2 states: IDLE, BUSY)
│   ├── Round counter (4 bits, 0-14)
│   ├── Key expansion counter (6 bits, 0-59)
│   └── Control signal generation
├── Key Expansion (aes_key_expansion)
│   ├── Rcon table (10 × 32-bit constants)
│   └── aes_sbox (for SubWord operation)
├── Encryption Round (aes_round)
│   ├── aes_sbox ×16 (parallel byte substitution)
│   ├── aes_shift_rows (row permutation)
│   ├── aes_mix_columns (GF(2^8) column mixing)
│   └── aes_add_round_key (128-bit XOR)
├── Decryption Round (aes_inv_round)
│   ├── aes_inv_sbox ×16 (inverse byte substitution)
│   ├── aes_inv_shift_rows (inverse row permutation)
│   ├── aes_inv_mix_columns (inverse GF(2^8) mixing)
│   └── aes_add_round_key (128-bit XOR)
└── State Register (128 bits)
    └── Four 32-bit column registers
```

## 4. Storage Elements

### 4.1 State Register

| Register | Width | Description |
|----------|-------|-------------|
| state_col0 | 32 bits | Column 0 of AES state matrix |
| state_col1 | 32 bits | Column 1 of AES state matrix |
| state_col2 | 32 bits | Column 2 of AES state matrix |
| state_col3 | 32 bits | Column 3 of AES state matrix |
| **Total** | **128 bits** | **AES state (4×4 bytes)** |

Byte ordering within a 32-bit column: `[byte3, byte2, byte1, byte0]` (big-endian)

### 4.2 Round Key Storage

| Register | Width | Count | Total | Description |
|----------|-------|-------|-------|-------------|
| round_key[i] | 128 bits | 15 | 1920 bits | Round keys 0-14 |
| **Total** | | | **1920 bits** | **All expanded keys** |

### 4.3 Control Registers

| Register | Width | Description |
|----------|-------|-------------|
| round_cnt | 4 bits | Current round (0-14) |
| key_cnt | 6 bits | Key expansion word index (0-59) |
| mode_reg | 1 bit | 0=encrypt, 1=decrypt (latched on start) |
| busy | 1 bit | High when processing |
| valid | 1 bit | Pulse when output ready |

### 4.4 Storage Summary

| Category | Bits | Flip-flops (approx) |
|----------|------|---------------------|
| State register | 128 | 128 |
| Round keys | 1920 | 1920 |
| Control | ~12 | ~12 |
| **Total** | **~2060 bits** | **~2060** |

## 5. Area Estimates

### 5.1 Flip-flop Area

- ~2060 flip-flops
- sky130 HD standard cell: ~12 µm² per flip-flop
- **Estimated FF area: ~25,000 µm²**

### 5.2 Combinational Logic Area

| Component | Gates | Area (µm²) |
|-----------|-------|------------|
| S-Box ×16 | ~800 | ~9,600 |
| Inv S-Box ×16 | ~800 | ~9,600 |
| ShiftRows | 0 (wires) | 0 |
| InvShiftRows | 0 (wires) | 0 |
| MixColumns ×4 | ~400 | ~4,800 |
| InvMixColumns ×4 | ~600 | ~7,200 |
| AddRoundKey | 128 XOR | ~1,500 |
| Key Expansion | ~400 | ~4,800 |
| Control FSM | ~100 | ~1,200 |
| Muxes | ~200 | ~2,400 |
| **Total Combo** | **~3400** | **~40,000** |

### 5.3 Total Area Estimate

| Component | Area (µm²) | Equivalent Gates |
|-----------|------------|------------------|
| Flip-flops | 25,000 | ~8,300 |
| Combinational | 40,000 | ~13,300 |
| **Total** | **~65,000** | **~21,600** |

**Note**: Slightly over 20k gates target. Can optimize by:
- Sharing S-Box between key expansion and datapath (saves ~600 gates)
- More compact MixColumns implementation (saves ~800 gates)
- Target: ~18,000 equivalent gates achievable

## 6. Timing Analysis

### 6.1 Critical Path

For encryption (similar for decryption):

```
State Register Q
    │
    ▼
S-Box lookup (combinational case statement)
    │
    ▼
ShiftRows (wire routing only)
    │
    ▼
MixColumns (4 parallel GF multipliers per column)
    │
    ▼
AddRoundKey (128 XOR gates)
    │
    ▼
State Register D
```

### 6.2 Path Delays (sky130 typical, estimated)

| Stage | Delay | Cumulative |
|-------|-------|------------|
| FF clock-to-Q | 0.3 ns | 0.3 ns |
| S-Box | 1.5 ns | 1.8 ns |
| ShiftRows | 0.1 ns | 1.9 ns |
| MixColumns | 2.0 ns | 3.9 ns |
| AddRoundKey | 0.5 ns | 4.4 ns |
| FF setup | 0.1 ns | 4.5 ns |

**Estimated critical path: ~4.5 ns**
**Maximum frequency: ~200 MHz**

**Margin at 50 MHz target: 4×** ✓

## 7. Power Considerations

### 7.1 Clock Gating Opportunities

- Key expansion logic can be gated after all keys computed
- Decrypt datapath gated when mode=encrypt (and vice versa)
- S-Box inputs registered to prevent glitches

### 7.2 Activity Factor

- State register: toggles every cycle during operation
- Round keys: static after expansion (low activity)
- Control: low activity (counters increment)

## 8. Design Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Architecture | Iterative | Area-optimized, matches spec |
| Key schedule | Pre-compute | Simpler control, 1920 bits storage |
| Round modules | Separate enc/dec | Better testability, cleaner design |
| State storage | 4×32-bit columns | Natural for MixColumns |
| S-Box | Case statement | Explicit, Yosys-friendly |
| FSM | 2-state + counter | Clean iterative control |
| Reset | Synchronous | Modern ASIC practice |
| MixColumns | Combinational | Single cycle, acceptable area |

## 9. Verification Strategy

See `docs/verification_plan.md` for complete test strategy.

### 9.1 Test Levels

1. **Unit tests**: Each leaf module (S-Box, MixColumns, etc.)
2. **Integration tests**: Round modules, Key Expansion
3. **System tests**: Full encrypt/decrypt with NIST vectors
4. **Corner cases**: All-zeros, all-ones, random vectors

### 9.2 NIST Test Vectors

- Encryption: FIPS-197 Appendix B
- Decryption: Inverse of encryption vector
- Key schedule: FIPS-197 Appendix A.3 (all 15 round keys)
- Round intermediates: For debugging

## 10. Synthesis Strategy

### 10.1 Yosys Flow

```tcl
read_verilog rtl/*.v
hierarchy -check -top aes_top
proc; opt; fsm; opt; memory; opt
techmap; opt; clean
synth -top aes_top
stat
write_verilog synth/aes_top_netlist.v
```

### 10.2 Target Library

- sky130_fd_sc_hd (high-density standard cells)
- Typical corner: tt_025C_1v80

### 10.3 Constraints

- Clock: 50 MHz (20 ns period)
- Input delay: 2 ns
- Output delay: 2 ns
- Load: 50 fF

## 11. Future Enhancements (Out of Scope)

| Feature | Complexity | Benefit |
|---------|------------|---------|
| Pipelined architecture | High | 14× throughput |
| Counter mode (CTR) | Medium | Stream cipher capability |
| Side-channel countermeasures | Very High | DPA/SPA resistance |
| AES-128/192 support | Low | Algorithm flexibility |

---

**Document Version**: 1.0
**Last Updated**: 2026-03-10
**Status**: Architecture Complete - RTL Implementation Authorized
