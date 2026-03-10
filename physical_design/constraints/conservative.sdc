# Conservative timing constraints for AES-256
# Target: 20MHz (50ns period) - relaxed for Sky130

create_clock -period 50 [get_ports clk]

# Clock uncertainty
set_clock_uncertainty 0.5 [get_clocks clk]

# Input delays (20% of clock period)
set_input_delay 10 -clock clk [all_inputs]

# Output delays (20% of clock period)
set_output_delay 10 -clock clk [all_outputs]

# False path for reset
set_false_path -from [get_ports rst_n]

# Multicycle paths for key expansion (if needed)
# set_multicycle_path 2 -from [get_cells key_exp_inst/*] -to [get_cells key_exp_inst/*]
