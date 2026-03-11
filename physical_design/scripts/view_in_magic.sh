#!/bin/bash
# View layout in Magic with proper zoom

RUN_DIR="/silicogenplayground/silicogen-project-2/physical_design/runs/run_20260310_222351"
RESULTS_DIR="$RUN_DIR/results"

# Check if .mag file exists
if [ ! -f "$RESULTS_DIR/aes_top.mag" ]; then
    echo "Creating Magic file from DEF..."
    cd "$RESULTS_DIR"
    magic -dnull -noconsole <<'EOF'
lef read /silicogenplayground/Work/vlsi/pdks/open_pdks/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/lef/sky130_osu_sc_15T_ls.lef
def read aes_top.def
save aes_top.mag
puts "Saved aes_top.mag"
EOF
fi

echo "=== Opening in Magic ==="
echo "File: $RESULTS_DIR/aes_top.mag"
echo ""
echo "Magic commands to use:"
echo "  zoom - zoom to fit everything"
echo "  findbox - zoom to selected area"
echo "  box size 1000um 1000um - set box to chip size"
echo "  expand - expand cell instances"
echo ""

# Open with GUI
cd "$RESULTS_DIR"
magic -d XR -rcfile /silicogenplayground/Work/vlsi/pdks/open_pdks/sky130/sky130A/libs.tech/magic/sky130A.magicrc <<'GUI' &
load aes_top.mag
box size 1000um 1000um
zoom
puts "Chip loaded! Use 'expand' to see cells"
GUI

echo "Magic started. If window is blank:"
echo "1. Click in the Magic window"
echo "2. Type: zoom"
echo "3. Type: expand"
echo "4. Or type: findbox"
