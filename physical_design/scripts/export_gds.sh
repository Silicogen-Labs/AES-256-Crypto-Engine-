#!/bin/bash
# Export DEF to GDS using Magic
# Usage: ./export_gds.sh [run_name]

PD_DIR="/silicogenplayground/silicogen-project-2/physical_design"
PDK_ROOT="/silicogenplayground/Work/vlsi/pdks/open_pdks"

# Find run directory
if [ -n "$1" ]; then
    RUN_DIR="$PD_DIR/runs/$1"
else
    RUN_DIR=$(ls -td $PD_DIR/runs/run_* 2>/dev/null | head -1)
fi

if [ -z "$RUN_DIR" ] || [ ! -d "$RUN_DIR" ]; then
    echo "❌ No run found"
    exit 1
fi

RUN_NAME=$(basename $RUN_DIR)
echo "=== Exporting GDS for: $RUN_NAME ==="

# Check for DEF file
DEF_FILE="$RUN_DIR/results/aes_top.def"
if [ ! -f "$DEF_FILE" ]; then
    echo "❌ DEF file not found: $DEF_FILE"
    exit 1
fi

GDS_FILE="$RUN_DIR/results/aes_top.gds"
GDS_LIB="$PDK_ROOT/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/gds/sky130_osu_sc_15t_ls.gds"

echo "DEF: $DEF_FILE"
echo "GDS Library: $GDS_LIB"
echo "Output: $GDS_FILE"

# Create Magic script
MAGIC_SCRIPT=$(cat <<EOF
gds read $GDS_LIB
lef read $PDK_ROOT/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/lef/sky130_osu_sc_15T_ls.lef
def read $DEF_FILE
gds write $GDS_FILE
quit
EOF
)

echo "Running Magic..."
cd "$RUN_DIR/results"
echo "$MAGIC_SCRIPT" | magic -noconsole -dnull -rcfile $PDK_ROOT/sky130/sky130A/libs.tech/magic/sky130A.magicrc 2>&1 | tee gds_export.log

if [ -f "$GDS_FILE" ]; then
    SIZE=$(ls -lh "$GDS_FILE" | awk '{print $5}')
    echo ""
    echo "✅ GDS exported successfully!"
    echo "   File: $GDS_FILE"
    echo "   Size: $SIZE"
else
    echo ""
    echo "❌ GDS export failed"
    echo "   Check log: $RUN_DIR/results/gds_export.log"
fi
