# Multi-cycle timing constraints for AES-256
# Target: 50MHz (20ns period) with multi-cycle paths
# This allows combinational paths to take multiple cycles

create_clock -period 20 [get_ports clk]

# Clock uncertainty
set_clock_uncertainty 0.5 [get_clocks clk]

# Input/Output delays
set_input_delay 4 -clock clk [all_inputs]
set_output_delay 4 -clock clk [all_outputs]

# False path for reset
set_false_path -from [get_ports rst_n]

# ============================================================
# MULTI-CYCLE PATHS
# Allow combinational paths to take multiple clock cycles
# ============================================================

# Round operations: 2 cycles (40ns available)
set_multicycle_path -setup 2 -from [get_cells round_*/inst/*] -to [get_cells round_*/inst/*]
set_multicycle_path -hold 1 -from [get_cells round_*/inst/*] -to [get_cells round_*/inst/*]

# Key expansion: 2 cycles
set_multicycle_path -setup 2 -from [get_cells key_exp_inst/*] -to [get_cells key_exp_inst/*]
set_multicycle_path -hold 1 -from [get_cells key_exp_inst/*] -to [get_cells key_exp_inst/*]

# S-box operations: 2 cycles
set_multicycle_path -setup 2 -from [get_cells *sbox*] -to [get_cells *sbox*]
set_multicycle_path -hold 1 -from [get_cells *sbox*] -to [get_cells *sbox*]

# Mix columns: 2 cycles
set_multicycle_path -setup 2 -from [get_cells *mix_columns*] -to [get_cells *mix_columns*]
set_multicycle_path -hold 1 -from [get_cells *mix_columns*] -to [get_cells *mix_columns*]

# ============================================================
# HIGH FANOUT NETS
# ============================================================

# rst_n has 4370 sinks - set as false path for timing
set_false_path -from [get_ports rst_n] -to [all_registers]

# ============================================================
# CONSTANT NETS (from synthesis)
# ============================================================

# These cause routing issues if optimized
set_dont_touch [get_nets zero_]
set_dont_touch [get_nets one_]
