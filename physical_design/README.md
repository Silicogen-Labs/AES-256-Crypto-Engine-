# Physical Design Flow

## Quick Start

```bash
# Run with relaxed constraints (recommended)
make pd-auto

# Run with specific constraints
PD_CONSTRAINT=moderate_50mhz.sdc make pd-auto

# List all runs
make pd-runs

# Clean old runs
make pd-cleanup
```

## Constraint Files

| File | Period | Frequency | Use Case |
|------|--------|-----------|----------|
| `relaxed_250mhz.sdc` | 250ns | 4MHz | Guaranteed success |
| `moderate_50mhz.sdc` | 50ns | 20MHz | Balanced |
| `aggressive_100mhz.sdc` | 10ns | 100MHz | Requires RTL pipelining |

## Timing Debug

The original design failed timing because:
- Combinational path: 207ns (S-boxes + key expansion)
- Clock period: 20ns
- Slack: -187ns (VIOLATED)

**Solutions:**
1. Use relaxed constraints (250ns)
2. Pipeline the RTL (add registers between rounds)
3. Optimize S-box implementation

## Directory Structure

```
physical_design/
├── constraints/      # SDC files
├── scripts/          # Tcl scripts
│   ├── pd_flow.tcl          # Main flow
│   └── timing_analysis.tcl  # Pre-PD analysis
└── runs/             # Timestamped runs
    └── run_YYYYMMDD_HHMMSS/
        ├── logs/         # Flow logs
        ├── reports/      # Area, timing, power
        ├── results/      # DEF, Verilog
        └── checkpoints/  # Intermediate saves
```

## Reports

Each run generates:
- `area.rpt` - Design area and utilization
- `timing.rpt` - Setup/hold timing analysis
- `power.rpt` - Dynamic and leakage power

## Advanced Usage

```bash
# Custom run directory
PD_RUN_DIR=runs/my_experiment make pd-auto

# Pre-PD timing analysis
cd scripts && openroad -exit timing_analysis.tcl
```
