#!/usr/bin/env ruby
# Save layout image using KLayout
# Run: klayout -b -r save_image.rb

# Configuration
run_dir = "/silicogenplayground/silicogen-project-2/physical_design/runs/run_20260310_222351"
def_file = "#{run_dir}/results/aes_top.def"
output_file = "#{run_dir}/images/layout.png"
lef_file = "/silicogenplayground/Work/vlsi/pdks/open_pdks/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/lef/sky130_osu_sc_15T_ls.lef"

puts "=== Generating Layout Image ==="
puts "DEF: #{def_file}"
puts "LEF: #{lef_file}"
puts "Output: #{output_file}"

# Create LEF/DEF reader configuration
lefdef_config = RBA::LEFDEFReaderConfiguration::new
lefdef_config.lef_files = [lef_file]
lefdef_config.dbu = 0.001

# Create load options
options = RBA::LoadLayoutOptions::new
options.lefdef_config = lefdef_config

# Create layout view
view = RBA::LayoutView::new

begin
  # Load layout
  view.load_layout(def_file, options, 0)
  puts "✅ Layout loaded"
  
  # Zoom to fit
  view.zoom_fit
  puts "✅ Zoomed to fit"
  
  # Create images directory
  Dir.mkdir("#{run_dir}/images") unless File.exist?("#{run_dir}/images")
  
  # Save image
  view.save_image(output_file, 1920, 1080)
  puts "✅ Image saved: #{output_file}"
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(5)
  exit 1
end
