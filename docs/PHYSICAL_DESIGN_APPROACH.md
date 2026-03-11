# Physical Design Approach: OpenROAD Flow

**Date**: 2026-03-10
**Status**: Implementation Phase
**Branch**: research/physical-impl

---

## 1. Architecture Decision: Industry Standard Flow

### Decision
Use **OpenROAD as a tool** (not OpenROAD-flow-scripts directly) with our own Tcl scripts and Makefile.

### Rationale
| Criterion | OpenROAD-flow-scripts Direct | Our Approach (Selected) |
|-----------|------------------------------|------------------------|
| Portability | ❌ Requires fixed paths | ✅ Works with any installation |
| Flexibility | ❌ Tied to their structure | ✅ Full control over flow |
| Maintainability | ❌ Hard to customize | ✅ Easy to modify |
| Industry Standard | ⚠️ Partial | ✅ Yes - IP blocks provide own scripts |
| User Experience | ⚠️ Complex setup | ✅ Clear error messages |

### Industry Precedent
- **OpenTitan**: Uses custom build system, calls OpenROAD as tool
- **PicoRV32**: Provides synthesis scripts, users install tools separately
- **RocketChip**: Makefile-based, tool-agnostic
- **Efabless**: Environment setup + tool invocation

---

## 2. Flow Architecture

```
┌─────────────────────────────────────────┐
│           User Interface                │
│         (Our Makefile)                  │
│                                         │
│   make pd  ──────────────────────┐      │
└──────────────────────────────────┼──────┘
                                   │
                                   ▼
┌─────────────────────────────────────────┐
│      Prerequisites Check                │
│  - OpenROAD in PATH?                    │
│  - PDK_ROOT set?                        │
│  - Netlist exists?                      │
└──────────────────────────────────┬──────┘
                                   │
                                   ▼
┌─────────────────────────────────────────┐
│      Our Physical Design Script         │
│    (physical_design/physical_design.tcl)│
│                                         │
│  1. Read PDK (LEF, Liberty)             │
│  2. Read Netlist                        │
│  3. Apply Constraints (SDC)             │
│  4. Floorplan                           │
│  5. Global Placement                    │
│  6. Detailed Placement                  │
│  7. Clock Tree Synthesis                │
│  8. Global Routing                      │
│  9. Detailed Routing                    │
│  10. Export GDS                         │
└─────────────────────────────────────────┘
```

---

## 3. File Structure

```
physical_design/
├── physical_design.tcl    # Main OpenROAD script
├── constraint.sdc         # Timing constraints
└── physical_design.log    # Generated log
```

### Script Responsibilities

| File | Responsibility |
|------|---------------|
| `Makefile` | User interface, tool detection, prerequisite checks |
| `physical_design.tcl` | OpenROAD commands, PDK interaction, flow control |
| `constraint.sdc` | Timing constraints (clock, I/O delays) |

---

## 4. Tool Interface

### Input Requirements
| Input | Source | Format |
|-------|--------|--------|
| Synthesized Netlist | Yosys (our synth/) | Verilog |
| Technology LEF | PDK | LEF |
| Standard Cell LEF | PDK | LEF |
| Liberty File | PDK | .lib |
| Constraints | Our design | SDC |

### Output Products
| Output | Description | Format |
|--------|-------------|--------|
| GDS | Mask layout for fabrication | GDSII |
| DEF | Design exchange format | DEF |
| Verilog | Post-layout netlist | Verilog |
| Reports | Area, timing, power | Text |

---

## 5. Configuration

### Environment Variables
```bash
export PDK_ROOT=/path/to/open_pdks  # Required
export OPENROAD=/path/to/openroad   # Optional (uses PATH if not set)
```

### Design Parameters (in Tcl)
| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Die Size | 500x500 µm | Estimated from gate count |
| Core Utilization | 60% | Balanced density |
| Target Frequency | 50 MHz | Conservative, achievable |
| Clock Uncertainty | 0.5 ns | Typical for sky130 |

---

## 6. Error Handling Strategy

### Prerequisite Checks (Makefile)
1. Check OpenROAD exists → Clear error if not
2. Check PDK_ROOT set → Clear error if not
3. Check netlist exists → Run synthesis if not

### Runtime Checks (Tcl)
1. Check files readable → Exit with error
2. Check commands succeed → Log and continue
3. Check results valid → Report metrics

### User Guidance
- Error messages include remediation steps
- Log file captures all output
- Progress indicators for long operations

---

## 7. Testing Strategy

### Unit Tests
| Test | Command | Expected Result |
|------|---------|-----------------|
| Tool detection | `make pd-check` | Pass if OpenROAD found |
| PDK check | `make pd-check` | Pass if PDK_ROOT set |
| Full flow | `make pd` | GDS generated, no errors |

### Validation Criteria
- [ ] GDS file generated (> 0 bytes)
- [ ] No DRC violations
- [ ] Timing met (setup/hold)
- [ ] Area within estimate (0.5-1.0 mm²)

---

## 8. Integration with Project

### Makefile Targets
```makefile
make sim    # Simulation (existing)
make synth  # Synthesis (existing)
make pd     # Physical design (NEW)
make all    # sim + synth
```

### Dependencies
```
pd: synth pd-check
    └─> physical_design.tcl
        └─> constraint.sdc
        └─> PDK files
```

---

## 9. Documentation for Users

### Quick Start
```bash
# 1. Install OpenROAD
#    See: https://openroad.readthedocs.io/

# 2. Install PDK
export PDK_ROOT=/path/to/open_pdks/sky130

# 3. Run physical design
make pd

# 4. View results
ls physical_design/*.gds
```

### Troubleshooting
| Issue | Solution |
|-------|----------|
| "OpenROAD not found" | Install OpenROAD and add to PATH |
| "PDK_ROOT not set" | Export PDK_ROOT environment variable |
| "Netlist not found" | Run `make synth` first |
| Routing congestion | Adjust PLACE_DENSITY in Tcl script |

---

## 10. Future Enhancements

### Phase 5B: Optimization
- [ ] Add multiple corner optimization
- [ ] Add power analysis
- [ ] Add IR drop analysis
- [ ] Add antenna check

### Phase 5C: Hardening
- [ ] Add IO pad ring
- [ ] Add seal ring
- [ ] Add filler cells
- [ ] Final DRC/LVS

---

## 11. Success Criteria

### Minimum Viable Product
- [ ] GDS generated without errors
- [ ] DRC clean (no violations)
- [ ] LVS clean (netlist matches layout)

### Full Success
- [ ] Timing closure at 50 MHz
- [ ] Area < 1.0 mm²
- [ ] Power estimate generated
- [ ] Visual layout confirmed

---

**Approach Status**: APPROVED for implementation
**Next Step**: Execute physical design flow
**Confidence**: HIGH (tools available, approach validated)
