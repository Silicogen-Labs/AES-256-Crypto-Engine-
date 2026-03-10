#!/usr/bin/env ruby
# Save layout image using KLayout
# Run: klayout -b -r save_image.rb

# Configuration
run_dir = ENV['PD_RUN_DIR'] || "/silicogenplayground/silicogen-project-2/physical_design/runs/run_20260310_222351"
def_file = "#{run_dir}/results/aes_top.def"
output_file = "#{run_dir}/images/layout.png"

puts "=== Generating Layout Image ==="
puts "DEF: #{def_file}"
puts "Output: #{output_file}"

# Create images directory
Dir.mkdir("#{run_dir}/images") unless File.exist?("#{run_dir}/images")

begin
  # Create layout view
  view = RBA::LayoutView::new
  
  # Load layout
  view.load_layout(def_file, 0)
  
  # Zoom to fit
  view.zoom_fit
  
  # Save image
  view.save_image(output_file, 1920, 1080)
  
  puts "✅ Image saved: #{output_file}"
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(5)
  exit 1
end
