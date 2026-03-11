# Relaxed timing constraints for AES-256
# Target: 4MHz (250ns period) - very relaxed for Sky130
# Use this to get a working layout first

create_clock -period 250 [get_ports clk]

# Clock uncertainty
set_clock_uncertainty 1.0 [get_clocks clk]

# Input delays (5% of clock period)
set_input_delay 12.5 -clock clk [all_inputs]

# Output delays (5% of clock period)  
set_output_delay 12.5 -clock clk [all_outputs]

# False path for reset
set_false_path -from [get_ports rst_n]

# Don't optimize constant 0/1 nets
set_dont_touch [get_nets zero_]
set_dont_touch [get_nets one_]
