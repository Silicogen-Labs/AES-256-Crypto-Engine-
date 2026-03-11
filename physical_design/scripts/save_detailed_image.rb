#!/usr/bin/env ruby
# Save detailed layout image showing cells
# Run: klayout -b -r save_detailed_image.rb

run_dir = "/silicogenplayground/silicogen-project-2/physical_design/runs/run_20260310_222351"
def_file = "#{run_dir}/results/aes_top.def"
output_file = "#{run_dir}/images/layout_detailed.png"
lef_file = "/silicogenplayground/Work/vlsi/pdks/open_pdks/sky130/sky130A/libs.ref/sky130_osu_sc_15t_ls/lef/sky130_osu_sc_15T_ls.lef"

puts "=== Generating Detailed Layout Image ==="
puts "DEF: #{def_file}"
puts "Output: #{output_file}"

# LEF/DEF config
lefdef_config = RBA::LEFDEFReaderConfiguration::new
lefdef_config.lef_files = [lef_file]
lefdef_config.dbu = 0.001

options = RBA::LoadLayoutOptions::new
options.lefdef_config = lefdef_config

view = RBA::LayoutView::new

begin
  view.load_layout(def_file, options, 0)
  puts "✅ Layout loaded"
  
  # Get layout object
  layout = view.active_cellview.layout
  
  # Find top cell
  top_cell = layout.top_cell
  puts "✅ Top cell: #{top_cell.name}"
  
  # Get bounding box
  bbox = top_cell.bbox
  puts "✅ Chip size: #{bbox.width} x #{bbox.height} um"
  
  # Zoom to specific region (center, zoomed in)
  # Show middle 20% of chip
  center_x = bbox.center.x
  center_y = bbox.center.y
  width = bbox.width * 0.2
  height = bbox.height * 0.2
  
  view.zoom_box(
    RBA::DBox::new(
      center_x - width/2, center_y - height/2,
      center_x + width/2, center_y + height/2
    )
  )
  puts "✅ Zoomed to center region"
  
  # Create images directory
  Dir.mkdir("#{run_dir}/images") unless File.exist?("#{run_dir}/images")
  
  # Save high-res image
  view.save_image(output_file, 2560, 1440)
  puts "✅ Image saved: #{output_file}"
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(5)
end
