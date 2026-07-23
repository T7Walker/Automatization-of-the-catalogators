# step_validator.py
import re


class StepValidator:
    """Validates step control integrity"""

    def __init__(self):
        self.validation_patterns = {
            'step_control_code': r'FM-\d{3}-\d+',
            'parametrization': r'^[MN]$',
            'class_object': r'.*\.class$',
        }

    def validate_step_control(self, step_control_data: dict) -> dict:
        """Validate step control completeness"""
        validations = {
            'code_valid': self._validate_code(step_control_data),
            'parametrization_valid': self._validate_parametrization(step_control_data),
            'objects_consistent': self._validate_objects(step_control_data),
            'paths_present': self._validate_paths(step_control_data)
        }
        return {
            'valid': all(validations.values()),
            'details': validations,
            'errors': self._get_errors(validations)
        }

    def _validate_code(self, data: dict) -> bool:
        code_azure = data.get('azure', {}).get('code', '')
        code_file = data.get('file_server', {}).get('code', '')
        valid_format = bool(re.match(self.validation_patterns['step_control_code'], code_azure))
        return valid_format and code_azure == code_file

    def _validate_parametrization(self, data: dict) -> bool:
        param_azure = data.get('azure', {}).get('parametrization', '')
        param_file = data.get('file_server', {}).get('parametrization', '')
        azure_valid = bool(re.match(self.validation_patterns['parametrization'], param_azure))
        file_valid = bool(re.match(self.validation_patterns['parametrization'], param_file))
        return azure_valid and file_valid and param_azure == param_file

    def _validate_objects(self, data: dict) -> bool:
        objects_azure = set(data.get('azure', {}).get('objects', []))
        objects_file = set(data.get('file_server', {}).get('objects', []))
        return objects_azure == objects_file

    def _validate_paths(self, data: dict) -> bool:
        dev_path = data.get('azure', {}).get('development_path', '')
        test_path = data.get('azure', {}).get('testing_path', '')
        return bool(dev_path and test_path)

    def _get_errors(self, validations: dict) -> list:
        errors = []
        if not validations['code_valid']:
            errors.append("Step control code is invalid or does not match")
        if not validations['parametrization_valid']:
            errors.append("Parametrization is invalid or does not match")
        if not validations['objects_consistent']:
            errors.append("Objects do not match between Azure and File Server")
        if not validations['paths_present']:
            errors.append("Development/testing paths not configured")
        return errors