#!/bin/bash
# Complete LVS flow: Extract netlist from GDS, then compare

RUN_DIR="/silicogenplayground/silicogen-project-2/physical_design/runs/run_20260310_222351"
RESULTS_DIR="$RUN_DIR/results"
REPORTS_DIR="$RUN_DIR/reports"
SYNTH_DIR="/silicogenplayground/silicogen-project-2/synth"

echo "=== LVS Complete Flow ==="
echo "Step 1: Extract netlist from GDS using Magic"
echo "Step 2: Compare with synthesis netlist using Netgen"
echo ""

cd "$RESULTS_DIR"

# Step 1: Extract netlist from GDS
echo "Step 1: Extracting netlist from GDS..."
magic -noconsole -dnull -rcfile /silicogenplayground/Work/vlsi/pdks/open_pdks/sky130/sky130A/libs.tech/magic/sky130A.magicrc <<'EOF' 2>&1 | tee "$REPORTS_DIR/ext2spice.log"
load aes_top.mag
puts "Loaded layout"

# Extract
extract all
puts "Extraction complete"

# Write SPICE netlist
ext2spice lvs
ext2spice -o aes_top_extracted.spice
puts "Netlist extracted to aes_top_extracted.spice"

quit
EOF

if [ ! -f "aes_top_extracted.spice" ]; then
    echo "❌ Extraction failed"
    exit 1
fi

echo "✅ Netlist extracted"

# Step 2: Run LVS
echo ""
echo "Step 2: Running LVS comparison..."

netgen -batch lvs "$SYNTH_DIR/aes_top_sky130.v aes_top" "aes_top_extracted.spice aes_top" \
  /silicogenplayground/Work/vlsi/pdks/open_pdks/sky130/sky130A/libs.tech/netgen/sky130A_setup.tcl \
  "$REPORTS_DIR/lvs_report.log" 2>&1

echo ""
echo "LVS complete!"
echo "Report: $REPORTS_DIR/lvs_report.log"

# Check result
if [ -f "$REPORTS_DIR/lvs_report.log" ]; then
    if grep -qi "match" "$REPORTS_DIR/lvs_report.log"; then
        echo "✅ LVS check complete - see report for details"
    else
        echo "⚠️  LVS completed - check report"
    fi
fi
