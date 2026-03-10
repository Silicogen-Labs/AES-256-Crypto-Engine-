# AES-256 Makefile
# Supports QuestaSim for simulation and Yosys for synthesis

# Directories
RTL_DIR = rtl
SIM_DIR = sim
SYNTH_DIR = synth

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
	@echo "  make clean  - Clean generated files"
	@echo "  make all    - Run both sim and synth"

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
