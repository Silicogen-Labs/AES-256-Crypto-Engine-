#!/bin/bash
# Visualize physical design results in KLayout

PD_DIR="/silicogenplayground/silicogen-project-2/physical_design"

# Find latest run
LATEST_RUN=$(ls -td $PD_DIR/runs/run_* 2>/dev/null | head -1)

if [ -z "$LATEST_RUN" ]; then
    echo "❌ No runs found"
    exit 1
fi

RUN_NAME=$(basename $LATEST_RUN)
echo "=== Visualizing: $RUN_NAME ==="

# Check for DEF file
DEF_FILE="$LATEST_RUN/results/aes_top.def"
if [ ! -f "$DEF_FILE" ]; then
    echo "❌ DEF file not found: $DEF_FILE"
    exit 1
fi

echo "DEF: $DEF_FILE"

# Check if KLayout is available
if command -v klayout &> /dev/null; then
    echo "🎨 Opening in KLayout..."
    klayout "$DEF_FILE" &
else
    echo "⚠️  KLayout not found. Install with:"
    echo "   sudo apt-get install klayout"
    echo ""
    echo "DEF file location:"
    echo "   $DEF_FILE"
fi

# Also show info
echo ""
echo "Run Info:"
echo "  Directory: $LATEST_RUN"
echo "  Checkpoints: $(ls $LATEST_RUN/checkpoints/*.odb 2>/dev/null | wc -l)"
echo "  Reports: $(ls $LATEST_RUN/reports/*.rpt 2>/dev/null | wc -l)"
echo ""
echo "To view reports:"
echo "  cat $LATEST_RUN/reports/final_area.rpt"
echo "  cat $LATEST_RUN/reports/final_timing.rpt"
