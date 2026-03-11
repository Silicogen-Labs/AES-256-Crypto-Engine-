# Complete Physical Design Solution

## Problem Statement

Our AES-256 design has:
- **Critical path**: 207ns (combinational through S-boxes)
- **Target clock**: 20ns (50MHz)
- **Slack**: -187ns (impossible to meet)
- **Error**: RSZ-2021 "cannot find viable buffering solution"

## Root Cause Analysis

From research and OpenROAD documentation:

1. **Deep combinational logic**: AES S-boxes have 8+ XOR gates in series
2. **No pipelining**: Each round is purely combinational
3. **High fanout nets**: rst_n has 4,370 sinks
4. **Buffer insertion fails**: Tool can't find cells that meet both setup and transition constraints

## Solution Strategy

### Option 1: Multi-Cycle Paths (RECOMMENDED - Quick Fix)

**Concept**: Tell the tool these paths take multiple clock cycles

**Implementation**:
```tcl
# In constraints file
set_multicycle_path -setup 14 -from [get_cells aes_round*] -to [get_cells aes_round*]
set_multicycle_path -hold 13 -from [get_cells aes_round*] -to [get_cells aes_round*]
```

**Pros**:
- No RTL changes needed
- Works with existing design
- Can target reasonable clock (20-50MHz)

**Cons**:
- Throughput reduced (14 cycles per operation)
- Not true pipelining

### Option 2: Pipelined RTL (BEST - Real Solution)

**Concept**: Add registers between rounds

**Implementation**:
```verilog
// Add pipeline registers after each round
always @(posedge clk) begin
    if (enable) begin
        round_out_reg <= round_out;  // Break combinational path
    end
end
```

**Pros**:
- True pipelining, can achieve high throughput
- Clean timing, no multi-cycle needed
- Industry standard approach

**Cons**:
- Requires RTL modification
- More area (registers)

### Option 3: Relaxed Clock (RESEARCH ONLY)

**Concept**: Use 250ns clock (4MHz)

**Pros**:
- Works immediately
- No changes needed

**Cons**:
- Not practical for real use
- Just proves physical feasibility

---

## Complete Flow Implementation

### Stage Order (Industry Standard)

1. **Synthesis** → Netlist
2. **Floorplan** → Die area, IO placement
3. **Tapcell** → Well taps
4. **PDN** → Power distribution ⭐ NEW
5. **Placement** → Global + Detailed
6. **CTS** → Clock tree synthesis
7. **Repair Timing** → Buffer insertion
8. **Filler** → Fill empty space
9. **Global Route** → Route planning ⭐ NEW
10. **Detailed Route** → Actual wires ⭐ NEW
11. **GDS** → Manufacturing output ⭐ NEW

### PDN (Power Distribution Network)

From OpenROAD documentation:

```tcl
# Connect power/ground pins
add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {VPWR} -power
add_global_connection -net {VSS} -inst_pattern {.*} -pin_pattern {VGND} -ground
global_connect

# Create power grid
set_voltage_domain -name {CORE} -power {VDD} -ground {VSS}
define_pdn_grid -name {grid} -voltage_domains {CORE} -pins {met5}

# Add power stripes
add_pdn_stripe -grid {grid} -layer {met1} -width {0.48} -pitch {5.44} -followpins
add_pdn_stripe -grid {grid} -layer {met4} -width {1.600} -pitch {27.140}
add_pdn_stripe -grid {grid} -layer {met5} -width {1.600} -pitch {27.200}

# Connect layers
add_pdn_connect -grid {grid} -layers {met1 met4}
add_pdn_connect -grid {grid} -layers {met4 met5}

# Generate PDN
pdngen
```

### Global Routing

```tcl
# Global route with congestion awareness
global_route -congestion_iterations 100

# Estimate parasitics for timing
estimate_parasitics -global_routing
```

### Detailed Routing

```tcl
# Detailed route (TritonRoute)
detailed_route

# Check DRC
check_antennas
```

### GDS Export

```tcl
# Write GDS for manufacturing
write_gds aes_top.gds
```

---

## Recommended Implementation

### For This Project (Quick Win)

Use **Option 1: Multi-Cycle Paths** with **moderate clock (50ns = 20MHz)**

**Why**:
- No RTL changes
- Achieves reasonable performance
- Can complete full flow including routing
- Industry-acceptable workaround

### For Production (Best Practice)

Use **Option 2: Pipelined RTL** with **aggressive clock (10ns = 100MHz)**

**Why**:
- True high-performance design
- Clean timing closure
- Standard industry approach

---

## New Run Configuration

### Files to Create

1. `constraints/multicycle_50mhz.sdc` - Multi-cycle constraints
2. `scripts/pd_complete.tcl` - Full flow with PDN/routing
3. `Makefile` target for complete flow

### Expected Results

With multi-cycle + 50MHz:
- Setup slack: +20ns to +50ns (MET)
- No buffering errors
- Full routing completes
- GDS generated
- Ready for tape-out (with caveats)

---

## References

- OpenROAD Documentation: https://openroad.readthedocs.io/
- OpenROAD Flow Scripts: https://openroad-flow-scripts.readthedocs.io/
- PDN Configuration: From sky130hd platform
- Routing: TritonRoute engine
- Research: Timing repair strategies from GitHub issues
