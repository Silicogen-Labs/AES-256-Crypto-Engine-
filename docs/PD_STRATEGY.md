# Physical Design Strategy & Debug Analysis

## Current Status: PLACEMENT COMPLETE, ROUTING BLOCKED

### What We Achieved
- Floorplan: 1mm x 1mm, 61% utilization
- Global + Detailed Placement: 35,863 cells placed
- Clock Tree Synthesis: 785 buffers, 9-level H-tree
- DEF + Verilog exported

### What Blocked Us: Timing Repair

**Error Analysis:**
```
[WARNING RSZ-2021] cannot find a viable buffering solution
[ERROR RSZ-0089] Could not find a resistance value for any corner
```

**Root Causes:**
1. **Tight clock constraint**: 10ns (100MHz) is too aggressive for Sky130
2. **Large combinational paths**: S-boxes have deep logic (8+ XOR gates in series)
3. **No wire RC setup**: Timing analysis couldn't calculate delays properly
4. **High fanout nets**: rst_n has 4,370 sinks, causing huge RC delay

**Why Buffering Failed:**
- Tool tried to insert buffers on long paths
- But cells were too large (high input capacitance)
- Couldn't meet both setup and transition constraints
- Got stuck in infinite loop trying different buffer combinations

---

## Strategy: Multi-Run Approach

### Run 1: Conservative Timing (IMMEDIATE)
**Goal**: Get a working routed design
**Approach**:
- Relax clock to 50ns (20MHz) - 5x slower
- Skip aggressive timing repair
- Focus on getting clean layout
- Generate GDS for visualization

### Run 2: Pipelined Design (FUTURE)
**Goal**: Achieve higher performance
**Approach**:
- Add pipeline registers after each round
- Break combinational paths
- Target 20ns (50MHz)
- Requires RTL modification

### Run 3: Shared S-boxes (AREA OPT)
**Goal**: Reduce area
**Approach**:
- Share S-box instances across rounds
- Increase latency (sequential execution)
- Smaller area, slower throughput

---

## Automated Flow Design

### Directory Structure
```
physical_design/
├── runs/                           # All PD runs
│   ├── run_20240310_210000/       # Timestamped runs
│   │   ├── config.tcl             # Run-specific config
│   │   ├── logs/                  # All logs
│   │   ├── reports/               # Generated reports
│   │   ├── results/               # DEF, GDS, etc.
│   │   └── checkpoints/           # Intermediate saves
│   ├── run_20240310_220000/
│   └── latest -> run_20240310_220000/  # Symlink
├── scripts/
│   ├── pd_flow.tcl               # Main flow
│   ├── report_gen.tcl            # Report generation
│   └── utils.tcl                 # Helper functions
└── constraints/
    ├── conservative.sdc          # 50ns clock
    ├── aggressive.sdc            # 10ns clock
    └── pipelined.sdc            # For future RTL
```

### Flow Stages
1. **INIT**: Setup directories, log start
2. **SYNTH**: Technology mapping (if needed)
3. **FLOORPLAN**: Initialize die area
4. **PLACE**: Global + detailed placement
5. **CTS**: Clock tree synthesis
6. **PDN**: Power distribution (NEW)
7. **ROUTE**: Global + detailed routing (NEW)
8. **FINISH**: Reports, cleanup

### Checkpointing Strategy
Save after each stage:
- `checkpoints/after_place.odb`
- `checkpoints/after_cts.odb`
- `checkpoints/after_route.odb`

Can resume from any checkpoint.

---

## Timing Constraint Strategy

### Current Problem
```tcl
# constraint.sdc - TOO AGGRESSIVE
create_clock -period 10 [get_ports clk]  ;# 100MHz
```

### Conservative Approach (Run 1)
```tcl
# conservative.sdc
create_clock -period 50 [get_ports clk]  ;# 20MHz
set_clock_uncertainty 0.5 [get_clocks clk]
set_input_delay 5 -clock clk [all_inputs]
set_output_delay 5 -clock clk [all_outputs]
```

### Why This Helps
1. **50ns vs 10ns**: 5x more time for signals
2. **Setup slack**: Was -187ns, now target +300ns
3. **Buffering**: Tool won't panic trying to fix violations
4. **Routing**: Can focus on connectivity, not timing

---

## Report Generation

### Metrics to Track
1. **Area**: Core, die, utilization %
2. **Timing**: WNS, TNS, Failing endpoints
3. **Power**: Dynamic, leakage, by component
4. **Routing**: Wirelength, congestion, DRCs
5. **Clock**: Skew, latency, buffer count

### Report Formats
- `summary.rpt`: Text summary
- `metrics.json`: Machine-readable
- `timing.html`: Visual timing report (if possible)

---

## Next Steps

1. Create automated flow script
2. Run with conservative constraints (50ns)
3. Generate full reports
4. If successful, try 20ns
5. Document results for each run
