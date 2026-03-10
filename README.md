# AES-256 Crypto Engine 🔐

A complete hardware implementation of the AES-256 encryption algorithm, designed for ASIC synthesis using open-source tools.

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Complete-brightgreen.svg)]()

## Overview

This project implements a complete AES-256 cryptographic engine in Verilog, verified with NIST test vectors and synthesized using Yosys.

### What is AES-256?

AES-256 is the Advanced Encryption Standard with 256-bit keys - the same encryption used by the US government to protect TOP SECRET information. It's virtually unbreakable with current technology.

## Features ✨

- **Complete AES-256 implementation**: Encryption and decryption
- **NIST FIPS-197 compliant**: Verified with official test vectors
- **Iterative architecture**: Area-optimized design
- **Fully synthesizable**: Yosys-compatible Verilog-2001
- **Self-checking testbench**: 6 comprehensive tests
- **Gate-level netlist**: Ready for ASIC fabrication

## Specifications

| Parameter | Value |
|-----------|-------|
| Algorithm | AES-256 (NIST FIPS-197) |
| Block Size | 128 bits |
| Key Size | 256 bits |
| Rounds | 14 |
| Latency | 17 cycles/block |
| Throughput | ~376 MB/s @ 50 MHz |
| Gate Count | ~15,000-18,000 equivalent gates |
| Flip-Flops | ~4,369 |

## Project Structure

```
├── rtl/                    # Verilog RTL modules
│   ├── aes_sbox.v         # S-Box lookup table
│   ├── aes_inv_sbox.v     # Inverse S-Box
│   ├── aes_shift_rows.v   # ShiftRows transformation
│   ├── aes_inv_shift_rows.v
│   ├── aes_mix_columns.v  # MixColumns transformation
│   ├── aes_inv_mix_columns.v
│   ├── aes_add_round_key.v
│   ├── aes_key_expansion.v
│   ├── aes_round.v        # Encryption round
│   ├── aes_inv_round.v    # Decryption round
│   └── aes_top.v          # Top-level module
├── sim/                    # Testbenches
│   └── tb_aes_top.sv      # SystemVerilog testbench
├── docs/                   # Documentation
│   ├── architecture.md
│   ├── datapath.md
│   ├── control_signals.md
│   └── ...
├── synth/                  # Synthesis output
│   └── aes_top_netlist.v  # Gate-level netlist
├── Makefile               # Build automation
└── .silicogenrules        # Design rules
```

## Quick Start

### Prerequisites

- QuestaSim or ModelSim (simulation)
- Yosys (synthesis)
- Make

### Simulation

```bash
make sim
```

Runs all 6 test cases:
1. NIST Encryption vector
2. NIST Decryption vector
3. All-zeros test
4. All-ones test
5. Roundtrip test
6. Back-to-back operations

### Synthesis

```bash
make synth
```

Generates gate-level netlist in `synth/aes_top_netlist.v`

## Test Results

All tests pass! ✅

```
Test 1: NIST Encryption          - PASS
Test 2: NIST Decryption          - PASS
Test 3: All Zeros Encrypt        - PASS
Test 4: All Ones Encrypt         - PASS
Test 5: Encrypt-Decrypt Roundtrip - PASS
Test 6: Back-to-Back Operations  - PASS
```

## Architecture

The design uses an **iterative architecture** where a single round datapath is reused for all 14 rounds, minimizing area.

### Block Diagram

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Key       │────▶│ Key Expansion│────▶│ 15 Round    │
│  (256-bit)  │     │ (8 cycles)   │     │   Keys      │
└─────────────┘     └──────────────┘     └─────────────┘
                                                │
┌─────────────┐     ┌──────────────┐     ┌────┴────────┐
│  Data In    │────▶│ Initial ARK  │────▶│ 14 Rounds │
│ (128-bit)   │     │ (Round 0)    │     │ (iterative) │
└─────────────┘     └──────────────┘     └────┬────────┘
                                              │
                                         ┌────┴────────┐
                                         │  Data Out   │
                                         │ (128-bit)   │
                                         └─────────────┘
```

## Documentation

- [Architecture Specification](docs/architecture.md)
- [Datapath Documentation](docs/datapath.md)
- [Control Signals](docs/control_signals.md)
- [Interface Specification](docs/interfaces.md)

## Synthesis Results

Using Yosys 0.63:

| Metric | Value |
|--------|-------|
| Total Cells | 33,495 |
| Flip-Flops | ~4,369 |
| Wires | 28,398 |
| Status | ✅ Success |

## Design Rules

This project follows the `.silicogenrules` methodology:
- Architecture before RTL
- Comprehensive documentation
- Systematic debugging
- Verification-driven development

## License

MIT License - See LICENSE file

## Acknowledgments

- NIST for the AES specification (FIPS-197)
- Yosys team for the open-source synthesis tool
- QuestaSim for simulation

---

**Co-authored by**: silicogen-bot (AI-assisted design)

*"AI agent designed a working AES-256 crypto chip"* 🚀
