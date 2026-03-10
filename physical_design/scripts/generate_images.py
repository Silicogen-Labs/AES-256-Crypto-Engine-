#!/usr/bin/env python3
"""
Generate visualization images from DEF files
Uses KLayout in batch mode to create PNG images
"""

import os
import sys
import json
import subprocess
from pathlib import Path

PD_ROOT = Path("/silicogenplayground/silicogen-project-2/physical_design")
RUNS_DIR = PD_ROOT / "runs"

def generate_layout_image(run_dir, output_file):
    """Generate layout image using KLayout"""
    def_file = run_dir / "results" / "aes_top.def"
    
    if not def_file.exists():
        print(f"❌ DEF file not found: {def_file}")
        return False
    
    # KLayout script to generate image
    klayout_script = f"""
    layout = RBA::Layout::new
    layout.read("{def_file}")
    
    # Create view
    view = RBA::LayoutView::new
    view.load_layout("{def_file}", 0)
    
    # Zoom to fit
    view.zoom_fit
    
    # Save image
    view.save_image("{output_file}", 1920, 1080)
    
    puts "Image saved: {output_file}"
    """
    
    script_file = run_dir / "temp_export.rb"
    with open(script_file, 'w') as f:
        f.write(klayout_script)
    
    try:
        result = subprocess.run(
            ['klayout', '-b', '-r', str(script_file)],
            capture_output=True,
            text=True,
            timeout=60
        )
        
        # Clean up
        script_file.unlink(missing_ok=True)
        
        if result.returncode == 0:
            print(f"✅ Image generated: {output_file}")
            return True
        else:
            print(f"⚠️  KLayout error: {result.stderr}")
            return False
    except Exception as e:
        print(f"❌ Error generating image: {e}")
        return False

def generate_run_images(run_name=None):
    """Generate images for a specific run or latest run"""
    if run_name is None:
        # Find latest run
        runs = sorted(RUNS_DIR.glob("run_*"), reverse=True)
        if not runs:
            print("❌ No runs found")
            return
        run_dir = runs[0]
    else:
        run_dir = RUNS_DIR / run_name
    
    if not run_dir.exists():
        print(f"❌ Run not found: {run_name}")
        return
    
    print(f"\n=== Generating Images for: {run_dir.name} ===\n")
    
    # Create images directory
    images_dir = run_dir / "images"
    images_dir.mkdir(exist_ok=True)
    
    # Generate layout image
    layout_png = images_dir / "layout.png"
    if generate_layout_image(run_dir, layout_png):
        print(f"   Layout: {layout_png}")
    
    # Generate stage summary image (text-based)
    summary_txt = images_dir / "summary.txt"
    generate_summary_text(run_dir, summary_txt)
    print(f"   Summary: {summary_txt}")
    
    print(f"\n✅ Images saved to: {images_dir}")

def generate_summary_text(run_dir, output_file):
    """Generate text summary of the run"""
    # Load config if exists
    config_file = run_dir / "config.json"
    config = {}
    if config_file.exists():
        with open(config_file) as f:
            config = json.load(f)
    
    # Count files
    checkpoints = list((run_dir / "checkpoints").glob("*.odb")) if (run_dir / "checkpoints").exists() else []
    reports = list((run_dir / "reports").glob("*.rpt")) if (run_dir / "reports").exists() else []
    results = list((run_dir / "results").glob("*")) if (run_dir / "results").exists() else []
    
    summary = f"""Physical Design Run Summary
============================
Run: {run_dir.name}
Status: {config.get('status', 'unknown')}
Constraint: {config.get('constraint', 'N/A')}
Created: {config.get('created', 'N/A')}

Stages Completed: {len(checkpoints)}
{chr(10).join(['  - ' + c.stem for c in sorted(checkpoints)])}

Reports Generated: {len(reports)}
Results Generated: {len(results)}
{chr(10).join(['  - ' + r.name for r in sorted(results)])}
"""
    
    with open(output_file, 'w') as f:
        f.write(summary)

def main():
    if len(sys.argv) > 1:
        run_name = sys.argv[1]
        generate_run_images(run_name)
    else:
        generate_run_images()

if __name__ == '__main__':
    main()
