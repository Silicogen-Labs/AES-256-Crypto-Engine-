# Physical Design Status

## Overview
AES-256 physical design implementation using OpenROAD and Sky130 PDK.

## Current Status: IN PROGRESS

### Completed Steps
1. **Technology Mapping** (Yosys)
   - Synthesized RTL to Sky130 OSU 15T standard cells
   - 35,863 standard cells
   - 585,096 um² area

2. **Floorplan** ✓
   - Die size: 1000 x 1000 um
   - Core area: 957,254 um²
   - Utilization: 61.1%

3. **Pin Placement** ✓
   - 518 I/O pins placed
   - HPWL: 276,500 um

4. **Tap Cell Insertion** ✓
   - 6,230 tap cells inserted

5. **Global Placement** ✓
   - 455 iterations
   - Final HPWL: 1,459,117 um

6. **Detailed Placement** ✓
   - Legalized placement
   - Max displacement: 18.2 um

7. **Clock Tree Synthesis** ✓
   - 785 clock buffers inserted
   - 4,369 sinks
   - 9-level H-tree
   - Average sink wire length: 1,097 um

8. **Timing Repair** - IN PROGRESS
   - Repairing 4,177 setup violations
   - Currently optimizing...

### Pending Steps
- Complete timing repair
- Filler insertion
- Export DEF/Verilog
- (Optional) Detailed routing for GDS

## Files
- `physical_design/physical_design.tcl` - Main script
- `physical_design/constraint.sdc` - Timing constraints
- `physical_design/test_pd.tcl` - Test script
- `synth/aes_top_sky130.v` - Technology-mapped netlist

## Commands
```bash
# Run physical design
export PDK_ROOT=/silicogenplayground/Work/vlsi/pdks/open_pdks
make pd

# Check progress
tail -f physical_design/physical_design.log
```

## Results (Expected)
- DEF file for layout
- Verilog netlist with physical cells
- Area: ~1 mm²
- Cell count: ~36K cells
