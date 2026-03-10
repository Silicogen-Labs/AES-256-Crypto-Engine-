# AES-256 Makefile
# Supports QuestaSim for simulation, Yosys for synthesis, and OpenROAD for physical design

# Directories
RTL_DIR = rtl
SIM_DIR = sim
SYNTH_DIR = synth
PD_DIR = physical_design

# Tool detection (use environment variables or system PATH)
VSIM ?= $(shell which vsim 2>/dev/null || echo /silicogenplayground/questasim/bin/vsim)
VLOG ?= $(shell which vlog 2>/dev/null || echo /silicogenplayground/questasim/bin/vlog)
VLIB ?= $(shell which vlib 2>/dev/null || echo /silicogenplayground/questasim/bin/vlib)
YOSYS ?= $(shell which yosys 2>/dev/null || echo /silicogenplayground/Work/vlsi/tools/OpenROAD-flow-scripts/tools/install/yosys/bin/yosys)
OPENROAD ?= $(shell which openroad 2>/dev/null || echo /silicogenplayground/Work/vlsi/tools/OpenROAD-flow-scripts/tools/install/OpenROAD/bin/openroad)

# RTL files
RTL_FILES = $(RTL_DIR)/aes_sbox.v \
            $(RTL_DIR)/aes_inv_sbox.v \
            $(RTL_DIR)/aes_shift_rows.v \
            $(RTL_DIR)/aes_inv_shift_rows.v \
            $(RTL_DIR)/aes_mix_columns.v \
            $(RTL_DIR)/aes_inv_mix_columns.v \
            $(RTL_DIR)/aes_add_round_key.v \
            $(RTL_DIR)/aes_key_expansion.v \
            $(RTL_DIR)/aes_round.v \
            $(RTL_DIR)/aes_inv_round.v \
            $(RTL_DIR)/aes_top.v

# Tools
VSIM = /silicogenplayground/questasim/bin/vsim
VLOG = /silicogenplayground/questasim/bin/vlog
VLIB = /silicogenplayground/questasim/bin/vlib
YOSYS = /silicogenplayground/Work/vlsi/tools/OpenROAD-flow-scripts/tools/install/yosys/bin/yosys

# Targets
.PHONY: all sim synth clean help

all: sim synth

help:
	@echo "AES-256 Makefile targets:"
	@echo "  make sim    - Run QuestaSim simulation"
	@echo "  make synth  - Run Yosys synthesis"
	@echo "  make pd     - Run OpenROAD physical design (requires PDK)"
	@echo "  make clean  - Clean generated files"
	@echo "  make all    - Run sim and synth"
	@echo ""
	@echo "Physical Design Setup:"
	@echo "  export PDK_ROOT=/path/to/pdks  # Required for physical design"
	@echo "  make pd                        # Run full RTL-to-GDS flow"

# Simulation
sim: work compile
	@echo "Running simulation..."
	$(VSIM) -c -work work tb_aes_top -do "run -all; quit -f"

work:
	$(VLIB) work

compile: work
	@echo "Compiling RTL files..."
	$(VLOG) -work work $(RTL_FILES)
	@echo "Compiling testbench..."
	$(VLOG) -work work -sv $(SIM_DIR)/tb_aes_top.sv

# Synthesis
synth:
	@echo "Running Yosys synthesis..."
	$(YOSYS) -p "read_verilog $(RTL_FILES); \
		synth -top aes_top; \
		stat; \
		write_verilog $(SYNTH_DIR)/aes_top_netlist.v"

# Synthesis for physical design (technology mapping to Sky130)
synth-pd: pd-check
	@echo "Running Yosys synthesis for physical design (Sky130)..."
	$(YOSYS) -p "read_verilog $(RTL_FILES); \
		synth -top aes_top; \
		dfflibmap -liberty $(PDK_ROOT)/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/lib/sky130_osu_sc_15T_ls_tt_1P89_25C.ccs.lib; \
		abc -liberty $(PDK_ROOT)/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/lib/sky130_osu_sc_15T_ls_tt_1P89_25C.ccs.lib -script +strash; \
		techmap; \
		opt -fast; \
		abc -liberty $(PDK_ROOT)/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/lib/sky130_osu_sc_15T_ls_tt_1P89_25C.ccs.lib; \
		stat -liberty $(PDK_ROOT)/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/lib/sky130_osu_sc_15T_ls_tt_1P89_25C.ccs.lib; \
		write_verilog $(SYNTH_DIR)/aes_top_sky130.v"

# Clean
clean:
	rm -rf work
	rm -f transcript
	rm -f *.vcd
	rm -f *.wlf
	rm -f $(SYNTH_DIR)/*.v
	@echo "Cleaned generated files"

# Debug - compile only
debug:
	$(VLOG) -work work $(RTL_FILES)

# Physical Design (OpenROAD)
.PHONY: pd pd-check

pd-check:
	@echo "Checking physical design prerequisites..."
	@if [ -z "$(OPENROAD)" ] || [ ! -x "$(OPENROAD)" ]; then \
		echo "ERROR: OpenROAD not found. Please install OpenROAD and add to PATH"; \
		echo "  See: https://openroad.readthedocs.io/en/latest/user/Build.html"; \
		exit 1; \
	fi
	@if [ -z "$(PDK_ROOT)" ]; then \
		echo "ERROR: PDK_ROOT not set. Please set PDK_ROOT environment variable"; \
		echo "  Example: export PDK_ROOT=/path/to/open_pdks"; \
		exit 1; \
	fi
	@echo "OpenROAD: $(OPENROAD)"
	@echo "PDK_ROOT: $(PDK_ROOT)"
	@echo "All prerequisites met!"

pd: synth pd-check
	@echo "Running OpenROAD physical design flow..."
	@echo "This will generate GDS layout from synthesized netlist"
	@mkdir -p $(PD_DIR)
	$(OPENROAD) -exit $(PD_DIR)/physical_design.tcl 2>&1 | tee $(PD_DIR)/physical_design.log
	@echo "Physical design complete. Results in $(PD_DIR)/"

pd-clean:
	rm -rf $(PD_DIR)
	@echo "Cleaned physical design files"

# Automated PD flow with timestamped runs
pd-auto: synth-pd pd-check
	@echo "Running automated physical design flow..."
	@mkdir -p $(PD_DIR)/runs
	@cd $(PD_DIR) && $(OPENROAD) -exit scripts/pd_flow.tcl 2>&1 | tee runs/latest_flow.log
	@echo "Flow complete. Check $(PD_DIR)/runs/latest/ for results"

# List all PD runs
pd-runs:
	@ls -lt $(PD_DIR)/runs/ | head -20

# Clean old runs (keep last 5)
pd-cleanup:
	@cd $(PD_DIR)/runs && ls -t | tail -n +6 | xargs -r rm -rf
	@echo "Cleaned old runs, kept last 5"

# Complete PD flow with PDN and routing
pd-complete: synth-pd pd-check
	@echo "Running COMPLETE physical design flow (with PDN + Routing)..."
	@mkdir -p $(PD_DIR)/runs
	@cd $(PD_DIR) && $(OPENROAD) -exit scripts/pd_complete.tcl 2>&1 | tee runs/latest_complete.log
	@echo "Complete flow finished. Check $(PD_DIR)/runs/ for results"

# Run with specific constraint
pd-mc: synth-pd pd-check
	@echo "Running PD with multi-cycle constraints..."
	@mkdir -p $(PD_DIR)/runs
	@cd $(PD_DIR) && PD_CONSTRAINT=multicycle_50mhz.sdc $(OPENROAD) -exit scripts/pd_complete.tcl 2>&1 | tee runs/latest_mc.log
	@echo "Multi-cycle flow finished"
