#!/bin/bash
# Visualize physical design results
# Usage: ./visualize.sh [run_name]

PD_DIR="/silicogenplayground/silicogen-project-2/physical_design"

# Find run directory
if [ -n "$1" ]; then
    RUN_DIR="$PD_DIR/runs/$1"
else
    # Find latest run
    RUN_DIR=$(ls -td $PD_DIR/runs/run_* 2>/dev/null | head -1)
fi

if [ -z "$RUN_DIR" ] || [ ! -d "$RUN_DIR" ]; then
    echo "❌ No run found"
    exit 1
fi

RUN_NAME=$(basename $RUN_DIR)
echo "=== Visualizing: $RUN_NAME ==="

# Create images directory
IMAGES_DIR="$RUN_DIR/images"
mkdir -p "$IMAGES_DIR"

# Check for DEF file
DEF_FILE="$RUN_DIR/results/aes_top.def"
if [ ! -f "$DEF_FILE" ]; then
    echo "❌ DEF file not found"
    exit 1
fi

echo "DEF: $DEF_FILE"

# Option 1: Open in KLayout GUI
echo ""
echo "Options:"
echo "  1) Open in KLayout GUI"
echo "  2) Generate screenshot (requires X11)"
echo "  3) Export to GDS first"
echo ""
read -p "Select option (1-3): " choice

case $choice in
    1)
        echo "🎨 Opening KLayout..."
        klayout "$DEF_FILE" &
        ;;
    2)
        echo "📸 Generating screenshot..."
        # This requires X11 display
        if [ -z "$DISPLAY" ]; then
            echo "⚠️  No DISPLAY available. Using Xvfb..."
            xvfb-run -a klayout -zz -r "$PD_DIR/scripts/export_image.py" "$DEF_FILE" "$IMAGES_DIR/layout.png"
        else
            klayout -zz -r "$PD_DIR/scripts/export_image.py" "$DEF_FILE" "$IMAGES_DIR/layout.png"
        fi
        echo "✅ Image saved: $IMAGES_DIR/layout.png"
        ;;
    3)
        echo "🔧 Exporting to GDS..."
        # Check if Magic is available
        if command -v magic &> /dev/null; then
            echo "Using Magic to export GDS..."
            cd "$RUN_DIR/results"
            magic -d XR -rcfile /silicogenplayground/Work/vlsi/pdks/open_pdks/sky130/sky130A/libs.tech/magic/sky130A.magicrc <<EOF
deff read aes_top.def
gds write aes_top.gds
quit
EOF
            echo "✅ GDS exported: $RUN_DIR/results/aes_top.gds"
            
            # Now open in KLayout
            if [ -f "$RUN_DIR/results/aes_top.gds" ]; then
                klayout "$RUN_DIR/results/aes_top.gds" &
            fi
        else
            echo "❌ Magic not available"
        fi
        ;;
    *)
        echo "Invalid option"
        ;;
esac

# Generate summary
echo ""
echo "=== Run Summary ==="
echo "Run: $RUN_NAME"
echo "Stages: $(ls $RUN_DIR/checkpoints/*.odb 2>/dev/null | wc -l)"
echo "Reports: $(ls $RUN_DIR/reports/*.rpt 2>/dev/null | wc -l)"
echo "Results:"
ls -lh $RUN_DIR/results/ 2>/dev/null | tail -n +2 | awk '{print "  - " $9 " (" $5 ")"}'

echo ""
echo "Images saved to: $IMAGES_DIR"
