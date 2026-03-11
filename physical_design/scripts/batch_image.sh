#!/bin/bash
# Generate layout image using KLayout batch mode with proper LEF loading

RUN_DIR="/silicogenplayground/silicogen-project-2/physical_design/runs/run_20260310_222351"
DEF_FILE="$RUN_DIR/results/aes_top.def"
IMAGES_DIR="$RUN_DIR/images"
LEF_FILE="/silicogenplayground/Work/vlsi/pdks/open_pdks/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/lef/sky130_osu_sc_15T_ls.lef"

echo "=== Generating Layout Image ==="
echo "DEF: $DEF_FILE"
echo "LEF: $LEF_FILE"
echo "Output: $IMAGES_DIR/layout.png"

mkdir -p "$IMAGES_DIR"

# Create KLayout script that loads LEF first
KLAYOUT_SCRIPT=$(cat <<EOF
# KLayout batch script
# Load LEF first
lef = RBA::Layout::new
lef.read("$LEF_FILE")

# Now load DEF (will reference LEF cells)
layout = RBA::Layout::new
layout.read("$DEF_FILE")

# Create view
view = RBA::LayoutView::new
view.load_layout("$DEF_FILE", 0)
view.zoom_fit
view.save_image("$IMAGES_DIR/layout.png", 1920, 1080)
puts "Image saved: $IMAGES_DIR/layout.png"
EOF
)

# Write script to temp file
echo "$KLAYOUT_SCRIPT" > /tmp/klayout_export.rb

# Run KLayout in batch mode
cd "$RUN_DIR/results"
klayout -b -r /tmp/klayout_export.rb 2>&1 | tee "$IMAGES_DIR/export.log"

# Check result
if [ -f "$IMAGES_DIR/layout.png" ]; then
    SIZE=$(ls -lh "$IMAGES_DIR/layout.png" | awk '{print $5}')
    echo ""
    echo "✅ Image generated: $IMAGES_DIR/layout.png ($SIZE)"
else
    echo ""
    echo "❌ Image generation failed"
    echo "Check log: $IMAGES_DIR/export.log"
fi
