# Automatization of the Catalogators

> Enterprise automation framework developed to streamline repetitive cataloging tasks through Python, PowerShell, Azure DevOps and AI-assisted validation.

---

## Overview

Automatization of the Catalogators is an internal automation platform designed to eliminate repetitive manual work performed by cataloging teams.

The project orchestrates multiple automation modules, validates business rules, integrates with Azure DevOps, executes PowerShell scripts and leverages AI to support decision making throughout the process.

The primary objective is to reduce execution time, minimize human error and standardize cataloging workflows.

---

## Features

- Automated cataloging workflow
- AI-assisted validation
- Azure DevOps integration
- PowerShell execution
- Notification system
- File management
- Logging and auditing
- Performance monitoring
- Modular architecture

---

## Architecture

```
                Input Files
                     │
                     ▼
           Workflow Orchestrator
                     │
      ┌──────────────┼──────────────┐
      ▼              ▼              ▼
 File Manager    AI Validator   Azure DevOps
      │              │              │
      └──────────────┼──────────────┘
                     ▼
          PowerShell Automation
                     │
                     ▼
              Notifications
                     │
                     ▼
                  Reports
```

---

## Project Structure

```
📁 CatalogAutomator/
├── 📁 core/               # Python core modules
│   ├── __init__.py
│   ├── config.py
│   ├── catalog_manager.py
│   ├── azure_handler.py
│   ├── ai_validator.py
│   ├── power_automate_client.py
│   ├── powershell_runner.py
│   ├── step_validator.py
│   ├── file_manager.py
│   └── notification_manager.py
├── 📁 scripts/            # PowerShell automation scripts
│   ├── main_orchestrator.ps1
│   ├── system_severity.ps1
│   ├── system_notifications.ps1
│   ├── threshold_config.ps1
│   ├── source_logic.ps1
│   ├── environment_preconditions.ps1
│   ├── link_verification.ps1
│   ├── auxiliary_functions.ps1
│   ├── record_handler.ps1
│   ├── file_operations.ps1
│   └── status_tracker.ps1
├── 📁 config/             # JSON configuration files
│   ├── environment.json
│   ├── log_config.json
│   └── paths.json
├── 📁 logs/               # Execution logs
├── 📁 backups/            # System backups
├── 📁 Documentation/      # Project documentation
└── README.md
```

Each module has a single responsibility, making the application easier to maintain and extend.

---

## Technologies

- **Python** - Core business logic, AI validation, API integration
- **PowerShell** - System operations, file management, notifications
- **Azure DevOps** - Work item management and tracking
- **Power Automate** - External notifications and workflows
- **scikit-learn** - TF-IDF text similarity for AI validation
- **JSON** - Configuration and data interchange

---

## Installation

```bash
# Clone the repository
git clone https://github.com/your-org/catalog-automator.git

# Navigate to project directory
cd catalog-automator

# Install Python dependencies
pip install -r requirements.txt
```

### Configuration

Edit the configuration files in the `config/` directory:

```json
// config/environment.json
{
    "project_name": "CatalogAutomator",
    "environment": "development",
    "base_path": "C:\\YourProjectPath"
}
```

### Run

```bash
python -m core.catalog_manager
```

---

## Workflow

1. **Read configuration** - Load environment and path settings
2. **Load files** - Read input data and step control documents
3. **Validate process** - Check preconditions and business rules
4. **Execute automation** - Run the main cataloging workflow
5. **AI validation** - Verify consistency using text similarity
6. **Generate logs** - Record all steps and results
7. **Notify results** - Send completion or error notifications

---

## Future Improvements

- Docker support for containerized deployment
- REST API for external integrations
- Web dashboard for real-time monitoring
- Parallel processing for batch operations
- Metrics dashboard with KPIs

---

## License

MIT