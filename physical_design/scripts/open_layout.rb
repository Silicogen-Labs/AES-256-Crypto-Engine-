#!/usr/bin/env ruby
# Open DEF with proper LEF configuration
# Run: klayout -r open_layout.rb

# Configuration
run_dir = "/silicogenplayground/silicogen-project-2/physical_design/runs/run_20260310_222351"
def_file = "#{run_dir}/results/aes_top.def"
lef_file = "/silicogenplayground/Work/vlsi/pdks/open_pdks/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/lef/sky130_osu_sc_15T_ls.lef"

puts "=== Opening Layout ==="
puts "DEF: #{def_file}"
puts "LEF: #{lef_file}"

# Create LEF/DEF reader configuration
lefdef_config = RBA::LEFDEFReaderConfiguration::new
lefdef_config.lef_files = [lef_file]
lefdef_config.dbu = 0.001  # Match DEF units

# Create load options
options = RBA::LoadLayoutOptions::new
options.lefdef_config = lefdef_config

# Create layout view
view = RBA::LayoutView::new

# Load with options
begin
  view.load_layout(def_file, options, 0)
  puts "✅ Layout loaded successfully"
  
  # Zoom to fit
  view.zoom_fit
  
  puts "✅ Ready for viewing"
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(5)
end
