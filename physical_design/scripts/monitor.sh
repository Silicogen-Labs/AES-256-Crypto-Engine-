#!/bin/bash
# Monitor physical design flow progress for a specific run

PD_DIR="/silicogenplayground/silicogen-project-2/physical_design"
RUNS_DIR="$PD_DIR/runs"

# Find the latest run directory
LATEST_RUN=$(ls -td $RUNS_DIR/run_* 2>/dev/null | head -1)

if [ -z "$LATEST_RUN" ]; then
    echo "=== PD Flow Monitor ==="
    echo "Time: $(date)"
    echo ""
    echo "Status: NO RUNS FOUND"
    echo "Start a run with: make pd-auto"
    exit 1
fi

RUN_NAME=$(basename $LATEST_RUN)
LOG_FILE="$LATEST_RUN/logs/flow.log"

echo "=== PD Flow Monitor ==="
echo "Time: $(date)"
echo "Run: $RUN_NAME"
echo "Directory: $LATEST_RUN"
echo ""

# Check if process is running
PID=$(pgrep -f "openroad.*pd_flow.tcl" | head -1)
if [ -n "$PID" ]; then
    echo "Status: 🟢 RUNNING (PID: $PID)"
    CPU=$(ps -p $PID -o %cpu= 2>/dev/null | xargs)
    MEM=$(ps -p $PID -o %mem= 2>/dev/null | xargs)
    TIME=$(ps -p $PID -o etime= 2>/dev/null | xargs)
    echo "CPU: ${CPU}% | Memory: ${MEM}% | Runtime: ${TIME}"
else
    echo "Status: 🔴 NOT RUNNING"
fi

echo ""
echo "=== Progress ==="

# Check which checkpoints exist
if [ -d "$LATEST_RUN/checkpoints" ]; then
    CHECKPOINTS=$(ls -1 $LATEST_RUN/checkpoints/*.odb 2>/dev/null | xargs -n1 basename 2>/dev/null | sed 's/.odb//' | tr '\n' ' ')
    if [ -n "$CHECKPOINTS" ]; then
        echo "✓ Completed stages: $CHECKPOINTS"
    else
        echo "○ No checkpoints yet (starting up...)"
    fi
fi

# Check for results
if [ -f "$LATEST_RUN/results/aes_top.def" ]; then
    echo "✓ DEF file generated"
fi
if [ -f "$LATEST_RUN/results/aes_top.v" ]; then
    echo "✓ Verilog netlist generated"
fi

echo ""
echo "=== Latest Activity ==="
if [ -f "$LOG_FILE" ]; then
    # Get last 5 meaningful log lines (skip warnings)
    tail -30 "$LOG_FILE" | grep -E "^\[|STAGE|complete|Checkpoint|Error" | tail -10
else
    echo "No log file yet"
fi

echo ""
echo "=== Reports ==="
if [ -d "$LATEST_RUN/reports" ]; then
    REPORTS=$(ls -1 $LATEST_RUN/reports/*.rpt 2>/dev/null | xargs -n1 basename 2>/dev/null | tr '\n' ' ')
    if [ -n "$REPORTS" ]; then
        echo "Available: $REPORTS"
    else
        echo "No reports generated yet"
    fi
fi

echo ""
echo "=== Quick Commands ==="
echo "Monitor:    $PD_DIR/scripts/monitor.sh"
echo "View log:   tail -f $LOG_FILE"
echo "Check area: cat $LATEST_RUN/reports/final_area.rpt"
echo "Check timing: cat $LATEST_RUN/reports/final_timing.rpt"
