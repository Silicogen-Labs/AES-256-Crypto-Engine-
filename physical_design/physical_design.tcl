#!/usr/bin/env openroad
# AES-256 Physical Design Script
# Industry standard: Tcl script called by OpenROAD

set design_name "aes_top"
set platform "sky130hd"

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

# Read synthesized netlist
read_verilog ../synth/aes_top_netlist.v

# Link design
link_design $design_name

# Read constraints
read_sdc constraint.sdc

# Initialize floorplan
# Core area: estimated based on gate count (~0.5-1.0 mm²)
# Using 500x500 microns as starting point
initialize_floorplan -die_area "0 0 500 500" -core_area "10 10 490 490"

# Place pins
place_pins -hor_layers met3 -ver_layers met2

# Global placement
global_placement -density 0.6

# Detailed placement
detailed_placement

# Clock tree synthesis
clock_tree_synthesis -root_buf sky130_osu_sc_15T_ls__buf_16 -buf_list sky130_osu_sc_15T_ls__buf_2

# Detailed routing
detailed_route

# Export results
write_def $design_name.def
write_verilog $design_name.v
write_gds $design_name.gds

# Reports
report_design_area
report_power
report_checks

puts "Physical design complete!"
puts "Results:"
puts "  - GDS: $design_name.gds"
puts "  - DEF: $design_name.def"
puts "  - Verilog: $design_name.v"
