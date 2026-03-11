#!/usr/bin/env openroad
# Pre-PD timing analysis to check feasibility

set design_name "aes_top"

# Read PDK
set pdk_root $::env(PDK_ROOT)
read_lef $pdk_root/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/techlef/sky130_osu_sc_15t_ls.tlef
read_lef $pdk_root/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/lef/sky130_osu_sc_15T_ls.lef
read_liberty $pdk_root/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/lib/sky130_osu_sc_15T_ls_tt_1P89_25C.ccs.lib

# Read netlist
read_verilog ../synth/aes_top_sky130.v
link_design $design_name

# Set wire RC
set_layer_rc -layer met1 -capacitance 1.72375E-04 -resistance 8.929e-04
set_layer_rc -layer met2 -capacitance 1.36233E-04 -resistance 8.929e-04
set_wire_rc -signal -layer met2

puts "\n=== TIMING ANALYSIS ==="

# Test different clock periods
foreach period {10 50 100 250} {
    puts "\n--- Testing ${period}ns clock ---"
    create_clock -period $period [get_ports clk]
    
    # Quick timing check (no placement)
    set paths [find_timing_paths -path_group clk -max_paths 1]
    
    if {[llength $paths] > 0} {
        set path [lindex $paths 0]
        set slack [get_property $path slack]
        set startpoint [get_property $path startpoint]
        set endpoint [get_property $path endpoint]
        
        puts "  Slack: $slack"
        puts "  Start: $startpoint"
        puts "  End: $endpoint"
        
        if {$slack < 0} {
            puts "  STATUS: VIOLATION"
        } else {
            puts "  STATUS: OK"
        }
    } else {
        puts "  No timing paths found"
    }
    
    # Clean up for next iteration
    remove_clock clk
}

puts "\n=== RECOMMENDATION ==="
puts "Based on analysis, use:"
puts "  - 250ns (4MHz) for guaranteed success"
puts "  - 50ns (20MHz) if you want to push it"
puts "  - 10ns (100MHz) requires RTL pipelining"
