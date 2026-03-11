#!/usr/bin/env ruby
# Open chip in KLayout with proper viewing

run_dir = "/silicogenplayground/silicogen-project-2/physical_design/runs/run_20260310_222351"
gds_file = "#{run_dir}/results/aes_top.gds"

puts "=== Opening Chip in KLayout ==="
puts "GDS: #{gds_file}"

if !File.exist?(gds_file)
  puts "❌ GDS file not found"
  puts "Run: ./physical_design/scripts/export_gds.sh"
  exit 1
end

# Create layout view
view = RBA::LayoutView::new

# Load GDS (has all geometry embedded)
view.load_layout(gds_file, 0)

# Get layout
layout = view.active_cellview.layout
top_cell = layout.top_cell

puts "✅ Loaded: #{top_cell.name}"
puts "✅ Cells: #{layout.cells}"
puts "✅ Layers: #{layout.layers}"

# Zoom to show everything
view.zoom_fit

puts "✅ Zoomed to fit"
puts "✅ Ready!"

# Keep window open
# (In GUI mode, this will show the window)
