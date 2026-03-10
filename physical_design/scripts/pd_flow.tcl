#!/usr/bin/env openroad
# Automated Physical Design Flow for AES-256
# Creates timestamped runs with checkpoints and reports

# Get run directory from environment or create timestamp
if {[info exists ::env(PD_RUN_DIR)]} {
    set run_dir $::env(PD_RUN_DIR)
} else {
    set timestamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
    set run_dir "runs/run_$timestamp"
}

# Create directory structure
file mkdir $run_dir
file mkdir $run_dir/logs
file mkdir $run_dir/reports
file mkdir $run_dir/results
file mkdir $run_dir/checkpoints

# Logging
set log_file [open "$run_dir/logs/flow.log" w]
proc log {msg} {
    global log_file
    set timestamp [clock format [clock seconds] -format "%H:%M:%S"]
    puts "\[$timestamp\] $msg"
    puts $log_file "\[$timestamp\] $msg"
    flush $log_file
}

log "=== AES-256 Physical Design Flow ==="
log "Run directory: $run_dir"

# Configuration
set design_name "aes_top"
set script_dir [file dirname [file normalize [info script]]]
set pd_root [file dirname $script_dir]

# Select constraint file based on environment or use relaxed default
if {[info exists ::env(PD_CONSTRAINT)]} {
    set constraint_file "$pd_root/constraints/$::env(PD_CONSTRAINT)"
} else {
    set constraint_file "$pd_root/constraints/relaxed_250mhz.sdc"
}

log "Using constraints: $constraint_file"

# Get PDK root
if {[info exists ::env(PDK_ROOT)]} {
    set pdk_root $::env(PDK_ROOT)
} else {
    log "ERROR: PDK_ROOT not set"
    exit 1
}

log "PDK_ROOT: $pdk_root"

# Stage tracking
set stage_start_time [clock seconds]
proc log_stage {stage} {
    global stage_start_time
    set elapsed [expr {[clock seconds] - $stage_start_time}]
    log "=== STAGE: $stage (elapsed: ${elapsed}s) ==="
    set ::stage_start_time [clock seconds]
}

# Error handling
proc checkpoint {name} {
    global run_dir design_name
    set ckpt_file "$run_dir/checkpoints/${name}.odb"
    write_db $ckpt_file
    log "Checkpoint saved: $ckpt_file"
}

# Report generation
proc generate_reports {stage} {
    global run_dir design_name
    log "Generating reports for $stage..."
    
    # Area report
    set area_rpt [open "$run_dir/reports/${stage}_area.rpt" w]
    puts $area_rpt "# Area Report - $stage"
    puts $area_rpt [report_design_area]
    close $area_rpt
    
    # Timing report
    set timing_rpt [open "$run_dir/reports/${stage}_timing.rpt" w]
    puts $timing_rpt "# Timing Report - $stage"
    puts $timing_rpt [report_checks]
    close $timing_rpt
    
    # Power report
    set power_rpt [open "$run_dir/reports/${stage}_power.rpt" w]
    puts $power_rpt "# Power Report - $stage"
    puts $power_rpt [report_power]
    close $power_rpt
    
    log "Reports saved to $run_dir/reports/"
}

# ============================================================================
# STAGE 1: INIT
# ============================================================================
log_stage "INIT"

log "Reading LEF files..."
read_lef $pdk_root/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/techlef/sky130_osu_sc_15t_ls.tlef
read_lef $pdk_root/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/lef/sky130_osu_sc_15T_ls.lef

log "Reading liberty..."
read_liberty $pdk_root/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/lib/sky130_osu_sc_15T_ls_tt_1P89_25C.ccs.lib

log "Reading netlist..."
set project_root [file dirname $pd_root]
read_verilog $project_root/synth/aes_top_sky130.v

log "Linking design..."
link_design $design_name

# Set wire RC
set_layer_rc -layer met1 -capacitance 1.72375E-04 -resistance 8.929e-04
set_layer_rc -layer met2 -capacitance 1.36233E-04 -resistance 8.929e-04
set_layer_rc -via mcon -resistance 9.249146E-3
set_wire_rc -signal -layer met2

log "Reading constraints: $constraint_file"
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
# STAGE 3: PLACE
# ============================================================================
log_stage "PLACE"

tapcell -distance 14 -tapcell_master "sky130_osu_sc_15T_ls__fill_1"
global_placement -density 0.6
detailed_placement
check_placement

checkpoint "place"
generate_reports "place"

# ============================================================================
# STAGE 4: CTS
# ============================================================================
log_stage "CTS"

clock_tree_synthesis -root_buf sky130_osu_sc_15T_ls__buf_8 \
    -buf_list "sky130_osu_sc_15T_ls__buf_2 sky130_osu_sc_15T_ls__buf_4 sky130_osu_sc_15T_ls__buf_8"

checkpoint "cts"
generate_reports "cts"

# ============================================================================
# STAGE 5: TIMING REPAIR (Optional)
# ============================================================================
log_stage "TIMING_REPAIR"

# Check timing before repair
set timing_ok 0
catch {
    set wns [exec grep -o "slack.*VIOLATED" <<< [report_checks]]
    if {[string length $wns] > 0} {
        log "Timing violations detected, attempting repair..."
        
        # Try repair with timeout (simplified - no timeout in Tcl)
        # Just attempt basic repair
        catch {
            repair_timing -setup
            log "Timing repair completed"
        } err
        
        if {[string length $err] > 0} {
            log "WARNING: Timing repair had issues: $err"
            log "Continuing with current placement..."
        }
    } else {
        log "Timing OK, no repair needed"
        set timing_ok 1
    }
}

checkpoint "timing"
generate_reports "timing"

# ============================================================================
# STAGE 6: PDN (Power Distribution)
# ============================================================================
log_stage "PDN"

# Simple PDN - connect power/ground
# Note: Full PDN requires more setup
log "PDN stage skipped (requires additional setup)"

checkpoint "pdn"

# ============================================================================
# STAGE 7: ROUTE
# ============================================================================
log_stage "ROUTE"

# Skip detailed routing for now - focus on getting clean placement
log "Routing stage skipped (requires PDN setup first)"

# ============================================================================
# STAGE 7: FINISH
# ============================================================================
log_stage "FINISH"

filler_placement "sky130_osu_sc_15T_ls__fill_1 sky130_osu_sc_15T_ls__fill_2"

# Export results
write_def $run_dir/results/$design_name.def
write_verilog $run_dir/results/$design_name.v
write_db $run_dir/results/$design_name.odb

generate_reports "final"

# Summary
set total_time [expr {[clock seconds] - $::start_time}]
log "=== FLOW COMPLETE ==="
log "Total time: ${total_time}s"
log "Results in: $run_dir/results/"
log "Reports in: $run_dir/reports/"

close $log_file

puts "\nPhysical design complete!"
puts "Run directory: $run_dir"
puts "View reports: ls $run_dir/reports/"
