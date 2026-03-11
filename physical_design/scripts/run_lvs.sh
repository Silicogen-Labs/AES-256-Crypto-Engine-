#!/bin/bash
# Run LVS using Netgen

RUN_DIR="/silicogenplayground/silicogen-project-2/physical_design/runs/run_20260310_222351"
RESULTS_DIR="$RUN_DIR/results"
REPORTS_DIR="$RUN_DIR/reports"
SYNTH_DIR="/silicogenplayground/silicogen-project-2/synth"

echo "=== Running LVS ==="
echo "Layout: aes_top.gds"
echo "Netlist: aes_top_sky130.v"
echo ""

cd "$RESULTS_DIR"

# Create LVS script
netgen -batch lvs "${SYNTH_DIR}/aes_top_sky130.v aes_top" "aes_top.gds aes_top" \
  /silicogenplayground/Work/vlsi/pdks/open_pdks/sky130/sky130A/libs.tech/netgen/sky130A_setup.tcl \
  "$REPORTS_DIR/lvs_report.log" 2>&1

echo ""
echo "LVS complete!"
echo "Report: $REPORTS_DIR/lvs_report.log"

# Check result
if grep -q "Circuits match uniquely" "$REPORTS_DIR/lvs_report.log" 2>/dev/null; then
    echo "✅ LVS PASSED - Circuits match!"
elif grep -q "Circuits match" "$REPORTS_DIR/lvs_report.log" 2>/dev/null; then
    echo "✅ LVS PASSED"
else
    echo "⚠️  LVS issues found - check report"
fi
