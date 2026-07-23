# file_manager.py
from .powershell_runner import PowerShellRunner


class FileManager:
    """File operations delegated to PowerShell"""

    def __init__(self):
        self.ps_runner = PowerShellRunner()

    def execute_operation(self, operation: str, parameters: dict) -> dict:
        """Execute file operation via PowerShell"""
        script_map = {
            'copy_dev_to_test': 'file_operations.ps1',
            'validate_structure': 'file_operations.ps1',
            'create_backup': 'file_operations.ps1'
        }

        script_name = script_map.get(operation)
        if not script_name:
            return {'success': False, 'error': f"Unsupported operation: {operation}"}

        params = {'-Operation': operation}
        for key, value in parameters.items():
            params[f"-{key}"] = str(value)

        return self.ps_runner.run(script_name, params)

    def copy_development_to_testing(self, source: str, destination: str, work_item_id: str) -> dict:
        """Coordinate copy from development to testing"""
        return self.execute_operation('copy_dev_to_test', {
            'Source': source,
            'Destination': destination,
            'WorkItemId': work_item_id
        })