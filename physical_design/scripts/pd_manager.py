#!/usr/bin/env python3
"""
Physical Design Manager - Modular PD Flow Controller
Usage: pd_manager.py <command> [options]

Commands:
  create    Create a new PD run with configuration
  list      List all runs with status
  status    Show detailed status of a run
  quick     Create and start a run in one command
"""

import os
import sys
import json
import subprocess
from datetime import datetime
from pathlib import Path

PD_ROOT = Path("/silicogenplayground/silicogen-project-2/physical_design")
RUNS_DIR = PD_ROOT / "runs"
CONSTRAINTS_DIR = PD_ROOT / "constraints"

class PDManager:
    def __init__(self):
        self.runs = self._discover_runs()
    
    def _discover_runs(self):
        """Discover all runs and their status"""
        runs = []
        if not RUNS_DIR.exists():
            return runs
        
        for run_dir in sorted(RUNS_DIR.glob("run_*"), reverse=True):
            run_info = self._get_run_info(run_dir)
            runs.append(run_info)
        return runs
    
    def _get_run_info(self, run_dir):
        """Get information about a specific run"""
        info = {
            'name': run_dir.name,
            'path': str(run_dir),
            'created': datetime.fromtimestamp(run_dir.stat().st_mtime).strftime('%Y-%m-%d %H:%M:%S'),
            'status': 'unknown',
            'stages': [],
            'reports': [],
            'results': []
        }
        
        # Check checkpoints
        checkpoints_dir = run_dir / 'checkpoints'
        if checkpoints_dir.exists():
            info['stages'] = [f.stem for f in checkpoints_dir.glob('*.odb')]
            if 'detailed_route' in info['stages']:
                info['status'] = 'completed'
            elif len(info['stages']) > 0:
                info['status'] = 'running'
        
        # Check reports
        reports_dir = run_dir / 'reports'
        if reports_dir.exists():
            info['reports'] = [f.name for f in reports_dir.glob('*.rpt')]
        
        # Check results
        results_dir = run_dir / 'results'
        if results_dir.exists():
            info['results'] = [f.name for f in results_dir.glob('*')]
        
        return info
    
    def create_run(self, name=None, constraint='multicycle_50mhz.sdc', description=''):
        """Create a new PD run"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        run_name = f"run_{timestamp}_{name}" if name else f"run_{timestamp}"
        run_dir = RUNS_DIR / run_name
        
        # Create directories
        (run_dir / 'checkpoints').mkdir(parents=True)
        (run_dir / 'reports').mkdir(parents=True)
        (run_dir / 'results').mkdir(parents=True)
        (run_dir / 'logs').mkdir(parents=True)
        
        # Create config file
        config = {
            'name': run_name,
            'constraint': constraint,
            'description': description,
            'created': timestamp,
            'status': 'created'
        }
        
        config_file = run_dir / 'config.json'
        with open(config_file, 'w') as f:
            json.dump(config, f, indent=2)
        
        print(f"✅ Created run: {run_name}")
        print(f"   Constraint: {constraint}")
        print(f"   Directory: {run_dir}")
        
        return run_name
    
    def start_run(self, run_name):
        """Start a PD run"""
        run_dir = RUNS_DIR / run_name
        if not run_dir.exists():
            print(f"❌ Run not found: {run_name}")
            return False
        
        # Load config
        config_file = run_dir / 'config.json'
        with open(config_file) as f:
            config = json.load(f)
        
        constraint = config.get('constraint', 'multicycle_50mhz.sdc')
        
        # Build command
        env = os.environ.copy()
        env['PD_RUN_DIR'] = str(run_dir)
        env['PD_CONSTRAINT'] = constraint
        
        script_path = str(PD_ROOT / 'scripts' / 'pd_complete.tcl')
        cmd = ['openroad', '-exit', script_path]
        
        log_file = run_dir / 'logs' / 'flow.log'
        
        print(f"🚀 Starting run: {run_name}")
        print(f"   Constraint: {constraint}")
        print(f"   Log: {log_file}")
        
        # Start in background
        log_path = str(log_file)
        with open(log_path, 'w') as log:
            process = subprocess.Popen(
                cmd,
                stdout=log,
                stderr=subprocess.STDOUT,
                cwd=str(PD_ROOT),
                env=env
            )
        
        # Update config
        config['status'] = 'running'
        config['pid'] = process.pid
        with open(config_file, 'w') as f:
            json.dump(config, f, indent=2)
        
        print(f"   PID: {process.pid}")
        return True
    
    def list_runs(self):
        """List all runs"""
        print("\n=== Physical Design Runs ===\n")
        print(f"{'Run Name':<35} {'Status':<12} {'Stages':<8} {'Created':<20}")
        print("-" * 85)
        
        for run in self.runs[:10]:
            stages = len(run['stages'])
            name = run['name'][:34]
            print(f"{name:<35} {run['status']:<12} {stages:<8} {run['created']:<20}")
    
    def show_status(self, run_name=None):
        """Show detailed status of a run"""
        if run_name is None and self.runs:
            run_name = self.runs[0]['name']
        
        if run_name is None:
            print("No runs found")
            return
        
        run_dir = RUNS_DIR / run_name
        if not run_dir.exists():
            print(f"❌ Run not found: {run_name}")
            return
        
        info = self._get_run_info(run_dir)
        
        print(f"\n=== Run: {info['name']} ===\n")
        print(f"Status: {info['status']}")
        print(f"Created: {info['created']}")
        print(f"Path: {info['path']}")
        
        print(f"\nStages ({len(info['stages'])}):")
        for stage in sorted(info['stages']):
            print(f"  ✓ {stage}")
        
        print(f"\nReports ({len(info['reports'])}):")
        for report in sorted(info['reports']):
            print(f"  - {report}")
        
        print(f"\nResults ({len(info['results'])}):")
        for result in sorted(info['results']):
            result_path = run_dir / 'results' / result
            if result_path.exists():
                size = result_path.stat().st_size
                size_mb = size / (1024 * 1024)
                print(f"  - {result} ({size_mb:.1f} MB)")
    
    def quick_run(self, name=None, constraint='multicycle_50mhz.sdc'):
        """Create and start a run in one command"""
        run_name = self.create_run(name, constraint)
        self.start_run(run_name)
        print(f"\n💡 Monitor with: python3 physical_design/scripts/pd_manager.py status")

def main():
    manager = PDManager()
    
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == 'create':
        name = sys.argv[2] if len(sys.argv) > 2 else None
        constraint = sys.argv[3] if len(sys.argv) > 3 else 'multicycle_50mhz.sdc'
        manager.create_run(name, constraint)
    
    elif command == 'start':
        run_name = sys.argv[2] if len(sys.argv) > 2 else None
        if run_name:
            manager.start_run(run_name)
        else:
            print("Usage: pd_manager.py start <run_name>")
    
    elif command == 'quick':
        name = sys.argv[2] if len(sys.argv) > 2 else None
        constraint = sys.argv[3] if len(sys.argv) > 3 else 'multicycle_50mhz.sdc'
        manager.quick_run(name, constraint)
    
    elif command == 'list':
        manager.list_runs()
    
    elif command == 'status':
        run_name = sys.argv[2] if len(sys.argv) > 2 else None
        manager.show_status(run_name)
    
    else:
        print(f"Unknown command: {command}")
        print(__doc__)

if __name__ == '__main__':
    main()
