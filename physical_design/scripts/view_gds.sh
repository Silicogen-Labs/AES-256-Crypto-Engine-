#!/bin/bash
# View GDS file in KLayout or generate image

RUN_DIR="/silicogenplayground/silicogen-project-2/physical_design/runs/run_20260310_222351"
GDS_FILE="$RUN_DIR/results/aes_top.gds"
IMAGES_DIR="$RUN_DIR/images"

echo "=== Viewing GDS Layout ==="
echo "GDS: $GDS_FILE"
echo ""

if [ ! -f "$GDS_FILE" ]; then
    echo "❌ GDS file not found"
    echo "Run: ./physical_design/scripts/export_gds.sh"
    exit 1
fi

# Check file size
SIZE=$(ls -lh "$GDS_FILE" | awk '{print $5}')
echo "GDS Size: $SIZE"
echo ""

# Option 1: Try to open in KLayout
echo "Options:"
echo "  1) Try opening in KLayout (may fail without display)"
echo "  2) Generate image using KLayout batch (may have issues)"
echo "  3) Just show file info"
echo ""
read -p "Select (1-3): " choice

case $choice in
    1)
        echo "Opening KLayout..."
        klayout "$GDS_FILE" &
        ;;
    2)
        echo "Generating image..."
        mkdir -p "$IMAGES_DIR"
        
        # Try using strm2gds or similar
        if command -v strm2gds &> /dev/null; then
            strm2gds "$GDS_FILE" -o "$IMAGES_DIR/layout.png"
        else
            echo "Image generation tools not available"
            echo "GDS file is ready: $GDS_FILE"
        fi
        ;;
    3)
        echo ""
        echo "GDS File Info:"
        ls -lh "$GDS_FILE"
        echo ""
        echo "To view on your local machine:"
        echo "  1. Copy GDS file: scp user@host:$GDS_FILE ."
        echo "  2. Open in KLayout: klayout aes_top.gds"
        ;;
esac
