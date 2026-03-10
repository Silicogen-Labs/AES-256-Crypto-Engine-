# Aggressive timing constraints for AES-256
# Target: 100MHz (10ns period) - requires pipelined RTL
# WILL FAIL with current RTL - for reference only

create_clock -period 10 [get_ports clk]

# Clock uncertainty
set_clock_uncertainty 0.2 [get_clocks clk]

# Input delays (20% of clock period)
set_input_delay 2 -clock clk [all_inputs]

# Output delays (20% of clock period)
set_output_delay 2 -clock clk [all_outputs]

# False path for reset
set_false_path -from [get_ports rst_n]

# NOTE: This requires pipelined RTL to work!
# Current RTL has 207ns combinational paths - will fail
