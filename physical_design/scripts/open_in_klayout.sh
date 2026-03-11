#!/bin/bash
# Open layout in KLayout with proper LEF setup

PD_ROOT="/silicogenplayground/silicogen-project-2/physical_design"
RUN_DIR="$PD_ROOT/runs/run_20260310_222351"
DEF_FILE="$RUN_DIR/results/aes_top.def"
LEF_FILE="/silicogenplayground/Work/vlsi/pdks/open_pdks/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/lef/sky130_osu_sc_15T_ls.lef"

echo "=== Opening Layout in KLayout ==="
echo "DEF: $DEF_FILE"
echo "LEF: $LEF_FILE"
echo ""

# Check if files exist
if [ ! -f "$DEF_FILE" ]; then
    echo "❌ DEF file not found"
    exit 1
fi

if [ ! -f "$LEF_FILE" ]; then
    echo "❌ LEF file not found"
    exit 1
fi

# Create a KLayout technology file
TECH_DIR="$RUN_DIR/.klayout"
mkdir -p "$TECH_DIR"

cat > "$TECH_DIR/tech.lyt" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<technology>
  <name>sky130_osu_15t</name>
  <description>Sky130 OSU 15T Technology</description>
  <dbu>0.001</dbu>
  <layer-properties_file></layer-properties_file>
  <add-other-layers>true</add-other-layers>
  <lefdef>
    <lef-files>$LEF_FILE</lef-files>
  </lefdef>
</technology>
EOF

echo "Created technology file: $TECH_DIR/tech.lyt"
echo ""

# Try to open with technology
export KLAYOUT_HOME="$TECH_DIR"
echo "Starting KLayout..."
echo "If LEF errors appear, the cells may need to be loaded manually"
echo ""

klayout -t sky130_osu_15t "$DEF_FILE" &

sleep 2
if pgrep -f "klayout.*$DEF_FILE" > /dev/null; then
    echo "✅ KLayout started successfully"
    echo "   PID: $(pgrep -f "klayout.*$DEF_FILE" | head -1)"
else
    echo "⚠️  KLayout may have failed to start"
    echo "   Try running: klayout $DEF_FILE"
fi
