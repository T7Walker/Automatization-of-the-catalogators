# config.py - Global configuration
import os
from pathlib import Path


# Azure DevOps Configuration
AZURE_DEVOPS_CONFIG = {
    'organization': os.getenv('AZURE_DEVOPS_ORG', 'my-organization'),
    'project': os.getenv('AZURE_DEVOPS_PROJECT', 'my-project'),
    'token': os.getenv('AZURE_DEVOPS_TOKEN', ''),
}

# Power Automate Configuration
POWER_AUTOMATE_CONFIG = {
    'flows': {
        'create_application_task': os.getenv('POWER_AUTOMATE_APPLICATION_URL', ''),
        'update_notification': os.getenv('POWER_AUTOMATE_UPDATE_URL', ''),
        'error_notification': os.getenv('POWER_AUTOMATE_ERROR_URL', ''),
    }
}

# Base Paths
BASE_DIR = Path(__file__).parent.parent

PATHS_CONFIG = {
    'core': str(BASE_DIR / 'core'),
    'scripts': str(BASE_DIR / 'scripts'),
    'logs': str(BASE_DIR / 'logs'),
    'backups': str(BASE_DIR / 'backups'),
}

# AI Configuration
AI_CONFIG = {
    'validation_model': 'models/validation_model.pkl',
    'confidence_threshold': 0.8,
    'search_patterns': [],
}