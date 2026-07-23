# power_automate_client.py
import requests
from .config import POWER_AUTOMATE_CONFIG


class PowerAutomateClient:
    """Power Automate API client"""

    def __init__(self):
        self.flows = POWER_AUTOMATE_CONFIG.get('flows', {})
        self.timeout = 30

    def create_application_task(self, work_item_id: str, testing_path: str, support_direction: str) -> bool:
        url = self.flows.get('create_application_task', '')
        if not url:
            print("⚠️ Power Automate URL not configured for create_application_task")
            return False
        payload = {
            "workItemId": work_item_id,
            "testingPath": testing_path,
            "supportDirection": support_direction,
            "type": "APPLICATION"
        }
        try:
            response = requests.post(url, json=payload, timeout=self.timeout)
            response.raise_for_status()
            print(f"✅ Application task created for {work_item_id}")
            return True
        except requests.exceptions.RequestException as e:
            print(f"❌ Error creating application task: {e}")
            return False

    def notify_update_completed(self, work_item_id: str) -> bool:
        url = self.flows.get('update_notification', '')
        if not url:
            print("⚠️ Power Automate URL not configured for update_notification")
            return False
        payload = {
            "workItemId": work_item_id,
            "type": "UPDATE_COMPLETED",
            "message": f"Update completed for support {work_item_id}"
        }
        try:
            response = requests.post(url, json=payload, timeout=self.timeout)
            response.raise_for_status()
            print(f"✅ Update notification sent for {work_item_id}")
            return True
        except requests.exceptions.RequestException as e:
            print(f"❌ Error notifying update: {e}")
            return False

    def notify_error(self, work_item_id: str, errors: list, support_direction: str) -> bool:
        url = self.flows.get('error_notification', '')
        if not url:
            print("⚠️ Power Automate URL not configured for error_notification")
            return False
        payload = {
            "workItemId": work_item_id,
            "errors": errors if isinstance(errors, list) else [errors],
            "supportDirection": support_direction,
            "type": "ERROR"
        }
        try:
            response = requests.post(url, json=payload, timeout=self.timeout)
            response.raise_for_status()
            print(f"✅ Error notification sent for {work_item_id}")
            return True
        except requests.exceptions.RequestException as e:
            print(f"❌ Error notifying error: {e}")
            return False