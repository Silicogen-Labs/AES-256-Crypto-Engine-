#!/bin/bash
# Run DRC using Magic

RUN_DIR="/silicogenplayground/silicogen-project-2/physical_design/runs/run_20260310_222351"
RESULTS_DIR="$RUN_DIR/results"
REPORTS_DIR="$RUN_DIR/reports"

echo "=== Running DRC ==="
echo "Design: aes_top"
echo ""

cd "$RESULTS_DIR"

# Run DRC in batch mode
magic -noconsole -dnull -rcfile /silicogenplayground/Work/vlsi/pdks/open_pdks/sky130/sky130A/libs.tech/magic/sky130A.magicrc <<'EOF' 2>&1 | tee "$REPORTS_DIR/drc_report.log"
load aes_top.mag
puts "Loaded design"

# Select everything
select top

# Run DRC
drc check
puts "DRC check complete"

# Save DRC errors to file
drc saveall "$REPORTS_DIR/drc_errors.rpt"
puts "DRC errors saved to drc_errors.rpt"

# Count errors
set drc_count [drc count]
puts "Total DRC errors: $drc_count"

# Summary
if {$drc_count == 0} {
    puts "✅ DRC CLEAN - No errors found!"
} else {
    puts "⚠️  DRC VIOLATIONS FOUND: $drc_count errors"
}

quit
EOF

echo ""
echo "DRC complete!"
echo "Report: $REPORTS_DIR/drc_report.log"
echo "Errors: $REPORTS_DIR/drc_errors.rpt"
