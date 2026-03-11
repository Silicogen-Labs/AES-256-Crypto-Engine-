# AES-256 Timing Constraints
# Target: 50 MHz (20ns period)

create_clock -name clk -period 20.0 [get_ports clk]

# Input delays (2ns)
set_input_delay -clock clk 2.0 [get_ports {start mode key* data_in*}]

# Output delays (2ns)
set_output_delay -clock clk 2.0 [get_ports {data_out* valid busy}]

# Reset
set_false_path -from [get_ports rst_n]

# Clock uncertainty
set_clock_uncertainty 0.5 [get_clocks clk]

# Clock transition
set_clock_transition 0.2 [get_clocks clk]
