# Moderate timing constraints for AES-256
# Target: 20MHz (50ns period) - reasonable for Sky130
# May still have violations but should complete

create_clock -period 50 [get_ports clk]

# Clock uncertainty
set_clock_uncertainty 0.5 [get_clocks clk]

# Input delays (10% of clock period)
set_input_delay 5 -clock clk [all_inputs]

# Output delays (10% of clock period)
set_output_delay 5 -clock clk [all_outputs]

# False path for reset
set_false_path -from [get_ports rst_n]

# Don't optimize constant 0/1 nets (causes routing issues)
set_dont_touch [get_nets zero_]
set_dont_touch [get_nets one_]

# Multicycle paths for key expansion (2 cycles)
set_multicycle_path 2 -from [get_cells key_exp_inst/*] -to [get_cells key_exp_inst/*]
