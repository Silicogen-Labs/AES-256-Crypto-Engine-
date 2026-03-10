#!/usr/bin/env openroad
# Complete Physical Design Flow for AES-256
# Includes PDN, Global Route, Detailed Route, GDS

# Get run directory
if {[info exists ::env(PD_RUN_DIR)]} {
    set run_dir $::env(PD_RUN_DIR)
} else {
    set timestamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
    set run_dir "runs/run_$timestamp"
}

file mkdir $run_dir/logs $run_dir/reports $run_dir/results $run_dir/checkpoints

# Logging
set log_file [open "$run_dir/logs/flow.log" w]
proc log {msg} {
    global log_file
    set ts [clock format [clock seconds] -format "%H:%M:%S"]
    puts "\[$ts\] $msg"
    puts $log_file "\[$ts\] $msg"
    flush $log_file
}

log "=== AES-256 Complete Physical Design ==="
log "Run directory: $run_dir"

# Setup paths
set design_name "aes_top"
set script_dir [file dirname [file normalize [info script]]]
set pd_root [file dirname $script_dir]
set project_root [file dirname $pd_root]

# Select constraint file
if {[info exists ::env(PD_CONSTRAINT)]} {
    set constraint_file "$pd_root/constraints/$::env(PD_CONSTRAINT)"
} else {
    set constraint_file "$pd_root/constraints/multicycle_50mhz.sdc"
}
log "Using constraints: $constraint_file"

# PDK setup
set pdk_root $::env(PDK_ROOT)

# Stage tracking
set stage_start [clock seconds]
proc log_stage {stage} {
    global stage_start
    set elapsed [expr {[clock seconds] - $stage_start}]
    log "=== STAGE: $stage (${elapsed}s) ==="
    set ::stage_start [clock seconds]
}

proc checkpoint {name} {
    global run_dir design_name
    set ckpt "$run_dir/checkpoints/${name}.odb"
    write_db $ckpt
    log "Checkpoint: $ckpt"
}

proc generate_reports {stage} {
    global run_dir
    log "Reports for $stage..."
    
    catch {
        set area_rpt [open "$run_dir/reports/${stage}_area.rpt" w]
        puts $area_rpt [report_design_area]
        close $area_rpt
    }
    
    catch {
        set timing_rpt [open "$run_dir/reports/${stage}_timing.rpt" w]
        puts $timing_rpt [report_checks]
        close $timing_rpt
    }
    
    catch {
        set power_rpt [open "$run_dir/reports/${stage}_power.rpt" w]
        puts $power_rpt [report_power]
        close $power_rpt
    }
}

# ============================================================================
# STAGE 1: INIT
# ============================================================================
log_stage "INIT"

read_lef $pdk_root/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/techlef/sky130_osu_sc_15t_ls.tlef
read_lef $pdk_root/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/lef/sky130_osu_sc_15T_ls.lef
read_liberty $pdk_root/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/lib/sky130_osu_sc_15T_ls_tt_1P89_25C.ccs.lib
read_verilog $project_root/synth/aes_top_sky130.v
link_design $design_name

set_layer_rc -layer met1 -capacitance 1.72375E-04 -resistance 8.929e-04
set_layer_rc -layer met2 -capacitance 1.36233E-04 -resistance 8.929e-04
set_layer_rc -via mcon -resistance 9.249146E-3
set_wire_rc -signal -layer met2

read_sdc $constraint_file
checkpoint "init"

# ============================================================================
# STAGE 2: FLOORPLAN
# ============================================================================
log_stage "FLOORPLAN"

initialize_floorplan -die_area "0 0 1000 1000" -core_area "10 10 990 990" -site 15T
make_tracks
place_pins -hor_layers met3 -ver_layers met2 -corner_avoidance 0 -min_distance 0.12

checkpoint "floorplan"
generate_reports "floorplan"

# ============================================================================
# STAGE 3: PDN (Power Distribution Network)
# ============================================================================
log_stage "PDN"

# Global connections
add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {VPWR} -power
add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {VDD} -power
add_global_connection -net {VSS} -inst_pattern {.*} -pin_pattern {VGND} -ground
add_global_connection -net {VSS} -inst_pattern {.*} -pin_pattern {VSS} -ground
global_connect

# Voltage domain
set_voltage_domain -name {CORE} -power {VDD} -ground {VSS}

# PDN grid
define_pdn_grid -name {grid} -voltage_domains {CORE} -pins {met5}
add_pdn_stripe -grid {grid} -layer {met1} -width {0.48} -pitch {5.44} -offset {0} -followpins
add_pdn_stripe -grid {grid} -layer {met4} -width {1.600} -pitch {27.140} -offset {13.570}
add_pdn_stripe -grid {grid} -layer {met5} -width {1.600} -pitch {27.200} -offset {13.600}
add_pdn_connect -grid {grid} -layers {met1 met4}
add_pdn_connect -grid {grid} -layers {met4 met5}

# Generate PDN
pdngen
log "PDN generated"

checkpoint "pdn"
generate_reports "pdn"

# ============================================================================
# STAGE 4: PLACE
# ============================================================================
log_stage "PLACE"

tapcell -distance 14 -tapcell_master "sky130_osu_sc_15T_ls__fill_1"
global_placement -density 0.6
detailed_placement
check_placement

checkpoint "place"
generate_reports "place"

# ============================================================================
# STAGE 5: CTS
# ============================================================================
log_stage "CTS"

clock_tree_synthesis -root_buf sky130_osu_sc_15T_ls__buf_8 \
    -buf_list "sky130_osu_sc_15T_ls__buf_2 sky130_osu_sc_15T_ls__buf_4 sky130_osu_sc_15T_ls__buf_8"

checkpoint "cts"
generate_reports "cts"

# ============================================================================
# STAGE 6: TIMING REPAIR
# ============================================================================
log_stage "TIMING_REPAIR"

# Use global routing parasitics for better accuracy
estimate_parasitics -placement

# Try repair timing with multi-cycle paths
catch {
    repair_timing -setup -max_iterations 5
    log "Setup repair attempted"
} err

if {[string length $err] > 0} {
    log "WARNING: Setup repair issues: $err"
}

catch {
    repair_timing -hold
    log "Hold repair completed"
} err

checkpoint "timing"
generate_reports "timing"

# ============================================================================
# STAGE 7: FILLER
# ============================================================================
log_stage "FILLER"

filler_placement "sky130_osu_sc_15T_ls__fill_1 sky130_osu_sc_15T_ls__fill_2"
checkpoint "filler"

# ============================================================================
# STAGE 8: GLOBAL ROUTE
# ============================================================================
log_stage "GLOBAL_ROUTE"

catch {
    global_route -congestion_iterations 100
    log "Global routing completed"
    
    # Update parasitics with global route info
    estimate_parasitics -global_routing
} err

if {[string length $err] > 0} {
    log "WARNING: Global routing issues: $err"
}

checkpoint "global_route"
generate_reports "global_route"

# ============================================================================
# STAGE 9: DETAILED ROUTE
# ============================================================================
log_stage "DETAILED_ROUTE"

catch {
    detailed_route
    log "Detailed routing completed"
} err

if {[string length $err] > 0} {
    log "WARNING: Detailed routing issues: $err"
}

checkpoint "detailed_route"
generate_reports "detailed_route"

# ============================================================================
# STAGE 10: FINISH
# ============================================================================
log_stage "FINISH"

# Export results
write_def $run_dir/results/$design_name.def
write_verilog $run_dir/results/$design_name.v
write_db $run_dir/results/$design_name.odb

# Try GDS export (requires additional setup)
catch {
    write_gds $run_dir/results/$design_name.gds
    log "GDS exported"
} err

if {[string length $err] > 0} {
    log "NOTE: GDS export requires additional setup"
}

generate_reports "final"

# Summary
set total_time [expr {[clock seconds] - $stage_start}]
log "=== FLOW COMPLETE ==="
log "Total time: ${total_time}s"
log "Results: $run_dir/results/"
log "Reports: $run_dir/reports/"

close $log_file

puts "\nPhysical design complete!"
puts "Run: $run_dir"
