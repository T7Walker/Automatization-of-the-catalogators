# notification_manager.py
from .power_automate_client import PowerAutomateClient
from .powershell_runner import PowerShellRunner


class NotificationManager:
    """Centralized notification handler"""

    def __init__(self):
        self.power_automate = PowerAutomateClient()
        self.ps_runner = PowerShellRunner()

    def send(self, notification_type: str, work_item_id: str, extra_data: dict = None) -> bool:
        """Send notification based on type"""
        handlers = {
            'validation_error': self._notify_validation_error,
            'promotion_completed': self._notify_promotion_completed,
            'application_scheduled': self._notify_application_scheduled,
            'update_completed': self._notify_update_completed
        }
        handler = handlers.get(notification_type)
        if handler:
            return handler(work_item_id, extra_data or {})
        raise ValueError(f"Unsupported notification type: {notification_type}")

    def _notify_validation_error(self, work_item_id, data):
        self.ps_runner.run("record_handler.ps1", {
            "-Context": "VALIDATION_ERROR",
            "-WorkItemId": work_item_id
        })
        return self.power_automate.notify_error(
            work_item_id,
            data.get('errors', []),
            data.get('support_direction', '')
        )

    def _notify_promotion_completed(self, work_item_id, data):
        return self.ps_runner.run("system_notifications.ps1", {
            "-Severity": "COMPLETED",
            "-Messages": f'["Promotion {work_item_id} completed"]',
            "-ProcessType": "PROMOTION",
            "-WorkItemId": work_item_id
        })

    def _notify_application_scheduled(self, work_item_id, data):
        return self.power_automate.create_application_task(
            work_item_id,
            data.get('testing_path', ''),
            data.get('support_direction', '')
        )

    def _notify_update_completed(self, work_item_id, data):
        return self.power_automate.notify_update_completed(work_item_id)