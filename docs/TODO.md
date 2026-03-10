# Physical Design TODO List

## Active Tasks

### High Priority
- [ ] **GDS Export**: Complete GDS generation for tape-out
  - Status: Pending
  - Blocker: Requires Magic/KLayout setup
  - Assigned: TBD

- [ ] **DRC/LVS Verification**: Run design rule checks
  - Status: Pending
  - Depends on: GDS export
  - Assigned: TBD

- [ ] **Timing Closure**: Improve timing to target 50MHz
  - Status: Research
  - Current: 4MHz (250ns) working
  - Target: 50MHz (20ns)
  - Strategy: Multi-cycle paths or pipelining

### Medium Priority
- [ ] **Power Analysis**: Run post-route power analysis
  - Status: Reports generated, need review
  - Location: `runs/*/reports/*_power.rpt`

- [ ] **Area Optimization**: Reduce core utilization
  - Current: 61%
  - Target: <70%
  - Status: Acceptable

- [ ] **Clock Skew Optimization**: Improve CTS quality
  - Current: 785 buffers, 9-level tree
  - Status: Working

### Low Priority
- [ ] **Documentation**: Complete user guide
  - Status: Partial
  - Files: `docs/PD_*.md`

- [ ] **Visualization**: Improve image generation
  - Status: Basic script created
  - Tool: KLayout batch mode

## Completed Tasks

- [x] **Floorplan**: Initialize die area
- [x] **Placement**: Global + detailed placement
- [x] **CTS**: Clock tree synthesis
- [x] **PDN**: Power distribution network
- [x] **Global Route**: Route planning
- [x] **Detailed Route**: Actual wire routing
- [x] **Multi-cycle Constraints**: Solve timing issues
- [x] **PD Manager**: Modular run management

## Bug Log

### Active Bugs

#### BUG-001: Timing Repair Warnings
- **Severity**: Low
- **Status**: Workaround applied
- **Description**: RSZ-2021 warnings during timing repair
- **Impact**: Flow completes, but timing not fully optimized
- **Workaround**: Multi-cycle constraints (2 cycles)
- **Root Cause**: 207ns combinational path vs 20ns clock
- **Fix**: Pipeline RTL or accept multi-cycle

#### BUG-002: GDS Export ✅ RESOLVED
- **Severity**: Medium
- **Status**: ✅ **FIXED**
- **Description**: GDS export using Magic
- **Solution**: Use Magic with GDS library reference
- **Command**: `./physical_design/scripts/export_gds.sh [run_name]`
- **Result**: 29MB GDS file generated
- **Location**: `runs/run_20260310_222351/results/aes_top.gds`
- **Date**: 2026-03-10

#### BUG-003: DRC Warnings
- **Severity**: Low
- **Status**: Monitoring
- **Description**: DRT-0305 warning in detailed route
- **Impact**: Minor, flow completes
- **Location**: `runs/*/logs/flow.log`

### Resolved Bugs

#### BUG-000: Timing Repair Hang
- **Severity**: High
- **Status**: ✅ Resolved
- **Description**: Flow stuck in timing repair
- **Fix**: Relaxed clock to 250ns, then multi-cycle constraints
- **Date**: 2026-03-10

## Feature Requests

### FR-001: Interactive GUI
- **Priority**: Medium
- **Description**: Web-based run monitoring
- **Status**: Planned

### FR-002: Auto-Constraint Selection
- **Priority**: High
- **Description**: Automatically choose best constraints
- **Status**: Research

### FR-003: Cloud Parallel Runs
- **Priority**: Low
- **Description**: Run multiple configurations in parallel
- **Status**: Future

## Run History

| Date | Run | Constraint | Status | Notes |
|------|-----|------------|--------|-------|
| 2026-03-10 | run_20260310_222351 | multicycle_50mhz.sdc | ✅ Complete | Full flow with routing |
| 2026-03-10 | run_20260310_214957 | relaxed_250mhz.sdc | ✅ Complete | Placement only |

## Next Steps

1. **Immediate**: ✅ Review generated reports - DONE
2. **Short-term**: 🔧 Fix GDS export using Magic
3. **Medium-term**: 🔍 DRC/LVS verification using Magic/Netgen
4. **Long-term**: ⚡ Timing optimization to 50MHz

## Available Tools

| Tool | Path | Purpose | Status |
|------|------|---------|--------|
| OpenROAD | `/silicogenplayground/Work/vlsi/tools/OpenROAD-flow-scripts` | PD flow | ✅ Working |
| Magic | `/silicogenplayground/Work/vlsi/tools/magic` | Layout/GDS/DRC | ✅ Available |
| Netgen | `/silicogenplayground/Work/vlsi/tools/netgen` | LVS | ✅ Available |
| KLayout | `/usr/bin/klayout` | Visualization | ✅ Available |
| ngspice | `/silicogenplayground/Work/vlsi/tools/ngspice` | Simulation | ✅ Available |
| xschem | `/silicogenplayground/Work/vlsi/tools/xschem` | Schematic | ✅ Available |

## Tool Versions

- OpenROAD: v26.1
- Magic: 8.3
- Netgen: 1.5
- KLayout: 0.28
- Sky130 PDK: 0.0.1
