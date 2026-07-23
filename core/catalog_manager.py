import json
from pathlib import Path
from .ai_validator import AIValidator
from .azure_handler import AzureHandler
from .power_automate_client import PowerAutomateClient
from .powershell_runner import PowerShellRunner


class CatalogManager:
    """Main orchestrator for catalog automation workflows"""

    def __init__(self):
        self.ai_validator = AIValidator()
        self.azure = AzureHandler()
        self.power_automate = PowerAutomateClient()
        self.ps_runner = PowerShellRunner()

    def promote_to_testing(self, work_item_id: str) -> bool:
        """Steps 1-6: Promote incident to testing environment"""
        print(f"🚀 INITIATING PROMOTION: {work_item_id}")

        try:
            # Step 1: Get support direction
            support_direction = self.azure.get_support_direction(work_item_id)
            print(f"📍 Support direction: {support_direction}")

            # Step 2: Get and analyze step control
            step_control_data = self.azure.get_step_control(work_item_id)

            # Step 2.1-2.2: AI analyzes documents
            ai_analysis = self.ai_validator.analyze_step_control(step_control_data)

            # Execute critical validations via PowerShell
            validation_result = self.ps_runner.run(
                "system_severity.ps1",
                {
                    "-ProcessType": "PROMOTION",
                    "-WorkItemId": work_item_id,
                    "-StepControlJson": json.dumps(step_control_data)
                }
            )

            if not validation_result.get("success", False):
                self._handle_error(
                    validation_result.get("errors", []),
                    work_item_id,
                    support_direction
                )
                return False

            # Steps 3-4: Copy development → testing
            paths = self.ai_validator.get_paths(step_control_data)
            file_operation = self.ps_runner.run(
                "file_operations.ps1",
                {
                    "-Source": paths.get("development", ""),
                    "-Destination": paths.get("testing", ""),
                    "-WorkItemId": work_item_id
                }
            )

            if not file_operation.get("success", False):
                raise Exception("File operation error")

            # Step 5: Update status in Azure DevOps
            self.azure.update_status(work_item_id, "Testing")

            # Step 6: Final notification
            message = self._generate_success_message(work_item_id, paths.get("testing", ""))
            self.ps_runner.run(
                "system_notifications.ps1",
                {
                    "-Severity": "COMPLETED",
                    "-Messages": json.dumps([message]),
                    "-ProcessType": "PROMOTION",
                    "-WorkItemId": work_item_id
                }
            )

            print("✅ PROMOTION COMPLETED SUCCESSFULLY")
            return True

        except Exception as e:
            print(f"❌ PROMOTION ERROR: {str(e)}")
            self._handle_error([str(e)], work_item_id, support_direction)
            return False

    def apply_to_testing(self, work_item_id: str) -> bool:
        """Apply to testing environment"""
        print(f"📦 INITIATING APPLICATION: {work_item_id}")

        try:
            support_direction = self.azure.get_support_direction(work_item_id)
            testing_path = self.azure.get_testing_path(work_item_id)

            dependencies = self.ai_validator.check_dependencies(work_item_id, testing_path)

            if dependencies.get("has_dependencies", False):
                self._handle_dependencies(dependencies, work_item_id)
                return False

            task_result = self.power_automate.create_application_task(
                work_item_id, testing_path, support_direction
            )

            print("✅ APPLICATION SCHEDULED")
            return True

        except Exception as e:
            print(f"❌ APPLICATION ERROR: {str(e)}")
            self._handle_error([str(e)], work_item_id, support_direction)
            return False

    def update_files(self, work_item_id: str) -> bool:
        """Update files workflow"""
        print(f"🔄 INITIATING UPDATE: {work_item_id}")

        try:
            changes = self.ai_validator.analyze_changes(work_item_id)

            update_result = self.ps_runner.run(
                "file_operations.ps1",
                {
                    "-Source": changes.get("development_path", ""),
                    "-Destination": changes.get("testing_path", ""),
                    "-WorkItemId": work_item_id
                }
            )

            if not update_result.get("success", False):
                raise Exception("File update error")

            change_log = self._generate_change_log(changes)
            self.azure.upload_attachment(work_item_id, change_log)

            self.power_automate.notify_update_completed(work_item_id)

            print("✅ UPDATE COMPLETED")
            return True

        except Exception as e:
            print(f"❌ UPDATE ERROR: {str(e)}")
            self._handle_error([str(e)], work_item_id, "N/A")
            return False

    def _handle_error(self, errors, work_item_id, support_direction):
        """Centralized error handling"""
        self.ps_runner.run(
            "record_handler.ps1",
            {"-Context": "ERROR", "-WorkItemId": work_item_id}
        )
        self.ps_runner.run(
            "system_notifications.ps1",
            {
                "-Severity": "HIGH",
                "-Messages": json.dumps(errors),
                "-ProcessType": "ERROR",
                "-WorkItemId": work_item_id
            }
        )
        error_message = self._generate_error_message(errors, support_direction)
        self.azure.add_comment(work_item_id, error_message)

    def _generate_success_message(self, work_item_id, testing_path):
        return f"""
Best regards

The support {work_item_id} is now in testing and awaiting
your application request.
Please confirm the date and testing environment.

PATH: {testing_path}

Thank you!
"""

    def _generate_error_message(self, errors, support_direction):
        return f"PROCESS ERROR: {'; '.join(errors)} | Direction: {support_direction}"

    def _generate_change_log(self, changes):
        return json.dumps(changes, indent=2, ensure_ascii=False)

    def _handle_dependencies(self, dependencies, work_item_id):
        print(f"⚠️ Dependencies detected for {work_item_id}: {dependencies.get('dependencies', [])}")
        self.azure.add_comment(
            work_item_id,
            f"Pending dependencies: {dependencies.get('dependencies', [])}"
        )