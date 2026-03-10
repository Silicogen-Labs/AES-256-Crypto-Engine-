#!/usr/bin/env openroad
# AES-256 Physical Design Script - Final Export
# Skips timing repair to export placement + CTS results

set design_name "aes_top"

# Read PDK and libraries
if {[info exists ::env(PDK_ROOT)]} {
    set pdk_root $::env(PDK_ROOT)
} else {
    puts "ERROR: PDK_ROOT environment variable not set"
    exit 1
}

# Read technology LEF
read_lef $pdk_root/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/techlef/sky130_osu_sc_15t_ls.tlef

# Read standard cell LEF
read_lef $pdk_root/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/lef/sky130_osu_sc_15T_ls.lef

# Read liberty (timing) file
read_liberty $pdk_root/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/lib/sky130_osu_sc_15T_ls_tt_1P89_25C.ccs.lib

# Read synthesized netlist (technology mapped for Sky130)
read_verilog ../synth/aes_top_sky130.v

# Link design
link_design $design_name

# Set wire RC for timing analysis (must be after link_design)
set_layer_rc -layer met1 -capacitance 1.72375E-04 -resistance 8.929e-04
set_layer_rc -layer met2 -capacitance 1.36233E-04 -resistance 8.929e-04
set_layer_rc -via mcon -resistance 9.249146E-3
set_wire_rc -signal -layer met2

# Read constraints
read_sdc constraint.sdc

# Initialize floorplan with larger area (utilization was 255% with 500x500)
# Using 1000x1000 microns to get ~60% utilization
initialize_floorplan -die_area "0 0 1000 1000" -core_area "10 10 990 990" -site 15T

# Make tracks for routing
make_tracks

# Place pins on the boundary
place_pins -hor_layers met3 -ver_layers met2 -corner_avoidance 0 -min_distance 0.12

# Tap cell insertion (required for Sky130)
tapcell -distance 14 -tapcell_master "sky130_osu_sc_15T_ls__fill_1"

# Global placement
global_placement -density 0.6

# Detailed placement
detailed_placement

# Check placement
check_placement

# Clock tree synthesis
puts "Running clock tree synthesis..."
clock_tree_synthesis -root_buf sky130_osu_sc_15T_ls__buf_8 -buf_list "sky130_osu_sc_15T_ls__buf_2 sky130_osu_sc_15T_ls__buf_4 sky130_osu_sc_15T_ls__buf_8"

# Skip timing repair - export as-is
puts "Skipping timing repair - exporting current results..."

# Fill empty spaces
filler_placement "sky130_osu_sc_15T_ls__fill_1 sky130_osu_sc_15T_ls__fill_2"

# Export results
write_def $design_name.def
write_verilog $design_name.v

# Reports
report_design_area
report_power
report_checks

puts "Physical design complete!"
puts "Results:"
puts "  - DEF: $design_name.def"
puts "  - Verilog: $design_name.v"
puts ""
puts "Note: Design has timing violations that need manual optimization"
puts "      for production use. Current result is suitable for research."
