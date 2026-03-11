#!/usr/bin/env openroad
# Quick test of physical design setup
# This just loads files and checks setup, doesn't run full flow

set design_name "aes_top"

# Read PDK and libraries
if {[info exists ::env(PDK_ROOT)]} {
    set pdk_root $::env(PDK_ROOT)
} else {
    puts "ERROR: PDK_ROOT environment variable not set"
    exit 1
}

puts "PDK_ROOT: $pdk_root"

# Read technology LEF
puts "Reading tech LEF..."
read_lef $pdk_root/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/techlef/sky130_osu_sc_15t_ls.tlef

# Read standard cell LEF
puts "Reading standard cell LEF..."
read_lef $pdk_root/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/lef/sky130_osu_sc_15T_ls.lef

# Read liberty (timing) file
puts "Reading liberty..."
read_liberty $pdk_root/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/lib/sky130_osu_sc_15T_ls_tt_1P89_25C.ccs.lib

# Read synthesized netlist
puts "Reading netlist..."
read_verilog ../synth/aes_top_sky130.v

# Link design
puts "Linking design..."
link_design $design_name

puts "SUCCESS: All files loaded correctly!"
puts "Design is ready for physical design."
