#!/usr/bin/env tclsh
# Export DEF to GDS using Magic
# Usage: magic -d XR -rcfile $PDK/sky130A.magicrc export_gds.tcl

set run_dir [lindex $argv 0]
if {$run_dir eq ""} {
    set run_dir "runs/run_20260310_222351"
}

set def_file "$run_dir/results/aes_top.def"
set gds_file "$run_dir/results/aes_top.gds"

puts "=== Exporting DEF to GDS ==="
puts "DEF: $def_file"
puts "GDS: $gds_file"

# Load LEF files
lef read /silicogenplayground/Work/vlsi/pdks/open_pdks/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/lef/sky130_osu_sc_15T_ls.lef

# Read DEF
def read $def_file

# Write GDS
gds write $gds_file

puts "✅ GDS exported: $gds_file"
puts "Done!"
