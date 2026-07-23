# powershell_runner.py
import subprocess
import json
from pathlib import Path


class PowerShellRunner:
    """Executes PowerShell scripts and returns results"""

    def __init__(self):
        self.scripts_dir = Path(__file__).parent.parent / 'scripts'

    def run(self, script_name: str, params: dict) -> dict:
        """Run a PowerShell script with parameters"""
        script_path = self.scripts_dir / script_name
        if not script_path.exists():
            return {"success": False, "errors": [f"Script not found: {script_path}"]}

        cmd = ["powershell", "-File", str(script_path)]
        for key, value in params.items():
            if isinstance(value, (dict, list)):
                cmd.extend([f"-{key}", json.dumps(value)])
            else:
                cmd.extend([f"-{key}", str(value)])

        try:
            result = subprocess.run(
                cmd, capture_output=True, text=True, encoding='utf-8', timeout=120
            )
            if result.returncode == 0 and result.stdout.strip():
                try:
                    return json.loads(result.stdout)
                except json.JSONDecodeError:
                    return {"success": True, "output": result.stdout}
            elif result.returncode == 0:
                return {"success": True, "output": result.stdout}
            else:
                return {"success": False, "errors": [result.stderr or "Unknown error"]}
        except subprocess.TimeoutExpired:
            return {"success": False, "errors": ["Timeout: PowerShell script exceeded 120s"]}
        except Exception as e:
            return {"success": False, "errors": [f"PowerShell error: {str(e)}"]}