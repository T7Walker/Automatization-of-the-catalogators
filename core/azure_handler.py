# azure_handler.py
import requests
import json
import base64
from .config import AZURE_DEVOPS_CONFIG


class AzureHandler:
    """Azure DevOps API handler"""

    def __init__(self):
        self.organization = AZURE_DEVOPS_CONFIG.get('organization', '')
        self.project = AZURE_DEVOPS_CONFIG.get('project', '')
        self.token = AZURE_DEVOPS_CONFIG.get('token', '')
        self.base_url = f"https://dev.azure.com/{self.organization}/{self.project}"
        self.headers = {'Content-Type': 'application/json-patch+json'}
        if self.token:
            token_bytes = f":{self.token}".encode('utf-8')
            self.headers['Authorization'] = f'Basic {base64.b64encode(token_bytes).decode()}'

    def _request(self, method, endpoint, data=None):
        url = f"{self.base_url}/_apis/wit/{endpoint}"
        try:
            if method == 'GET':
                response = requests.get(url, headers=self.headers, timeout=30)
            elif method == 'PATCH':
                response = requests.patch(url, headers=self.headers, data=json.dumps(data), timeout=30)
            else:
                raise ValueError(f"Unsupported method: {method}")
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"❌ Azure DevOps request error: {e}")
            raise

    def get_work_item(self, work_item_id):
        return self._request('GET', f"workitems/{work_item_id}?api-version=6.0")

    def get_support_direction(self, work_item_id):
        work_item = self.get_work_item(work_item_id)
        return work_item['fields'].get('System.AreaPath', '')

    def get_testing_path(self, work_item_id):
        work_item = self.get_work_item(work_item_id)
        return work_item['fields'].get('Custom.TestingPath', '')

    def get_step_control(self, work_item_id):
        work_item = self.get_work_item(work_item_id)
        return {
            'azure': {
                'code': work_item['fields'].get('Custom.StepControlCode', ''),
                'parametrization': work_item['fields'].get('Custom.Parametrization', ''),
                'objects': self._extract_objects(work_item),
                'development_path': work_item['fields'].get('Custom.DevelopmentPath', ''),
                'testing_path': work_item['fields'].get('Custom.TestingPath', '')
            },
            'file_server': {
                'content': self._get_file_server_content(work_item),
                'code': '',
                'parametrization': '',
                'objects': [],
                'recommendations': ''
            }
        }

    def update_status(self, work_item_id, new_status):
        body = [{"op": "add", "path": "/fields/System.State", "value": new_status}]
        return self._request('PATCH', f"workitems/{work_item_id}?api-version=6.0", data=body)

    def add_comment(self, work_item_id, comment):
        body = [{"op": "add", "path": "/fields/System.History", "value": comment}]
        return self._request('PATCH', f"workitems/{work_item_id}?api-version=6.0", data=body)

    def upload_attachment(self, work_item_id, file_path):
        print(f"📎 Attaching file to {work_item_id}: {file_path}")

    def _extract_objects(self, work_item):
        return []

    def _get_file_server_content(self, work_item):
        return ""