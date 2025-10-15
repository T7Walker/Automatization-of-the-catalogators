# azure_handler.py
import requests
import json
import os
from config import AZURE_DEVOPS_CONFIG

class AzureHandler:
    def __init__(self):
        self.organization = AZURE_DEVOPS_CONFIG['organization']
        self.project = AZURE_DEVOPS_CONFIG['project']
        self.token = AZURE_DEVOPS_CONFIG['token']
        self.base_url = f"https://dev.azure.com/{self.organization}/{self.project}"
        self.headers = {
            'Content-Type': 'application/json-patch+json',
            'Authorization': f'Basic {self.token}'
        }
    
    def obtener_direccion_atencion(self, work_item_id):
        """Obtiene la dirección de atención desde Azure DevOps"""
        work_item = self.obtener_work_item(work_item_id)
        area_path = work_item['fields']['System.AreaPath']
        
        # Mapear AreaPath a dirección de atención
        direcciones = {
            "DireccionA": "ETIQUETA_DIRECCION_A",
            "DireccionB": "ETIQUETA_DIRECCION_B",
            # ... agregar tus direcciones específicas
        }
        
        return direcciones.get(area_path, "ETIQUETA_GENERICA")
    
    def obtener_control_pasos(self, work_item_id):
        """Obtiene datos del control de pasos FM-169"""
        work_item = self.obtener_work_item(work_item_id)
        
        control_pasos_data = {
            'azure': {
                'codigo': work_item['fields'].get('Custom.CodigoControlPasos', ''),
                'parametrizacion': work_item['fields'].get('Custom.Parametrizacion', ''),
                'objetos': self._extraer_objetos_azure(work_item),
                'ruta_desarrollo': work_item['fields'].get('Custom.RutaDesarrollo', ''),
                'ruta_pruebas': work_item['fields'].get('Custom.RutaPruebas', '')
            },
            'file_server': {
                'contenido': self._obtener_contenido_file_server(work_item),
                'codigo': '',
                'parametrizacion': '',
                'objetos': [],
                'recomendaciones': ''
            }
        }
        
        return control_pasos_data
    
    def obtener_work_item(self, work_item_id):
        """Obtiene un work item de Azure DevOps"""
        url = f"{self.base_url}/_apis/wit/workitems/{work_item_id}?api-version=6.0"
        
        response = requests.get(url, headers=self.headers)
        response.raise_for_status()
        
        return response.json()
    
    def actualizar_estado(self, work_item_id, nuevo_estado):
        """Actualiza el estado de un work item"""
        url = f"{self.base_url}/_apis/wit/workitems/{work_item_id}?api-version=6.0"
        
        body = [
            {
                "op": "add",
                "path": "/fields/System.State",
                "value": nuevo_estado
            }
        ]
        
        response = requests.patch(url, headers=self.headers, data=json.dumps(body))
        response.raise_for_status()
        
        return response.json()
    
    def agregar_comentario(self, work_item_id, comentario):
        """Agrega un comentario al work item"""
        url = f"{self.base_url}/_apis/wit/workitems/{work_item_id}?api-version=6.0"
        
        body = [
            {
                "op": "add",
                "path": "/fields/System.History",
                "value": comentario
            }
        ]
        
        response = requests.patch(url, headers=self.headers, data=json.dumps(body))
        response.raise_for_status()
        
        return response.json()
    
    def subir_adjunto(self, work_item_id, archivo_path):
        """Sube un archivo como adjunto al work item"""
        # Implementar lógica para subir adjuntos
        pass
    
    def _extraer_objetos_azure(self, work_item):
        """Extrae objetos del control de pasos en Azure"""
        descripcion = work_item['fields'].get('System.Description', '')
        # Lógica para extraer objetos de la descripción
        return []
    
    def _obtener_contenido_file_server(self, work_item):
        """Obtiene contenido del control de pasos en File Server"""
        ruta_file_server = work_item['fields'].get('Custom.RutaFileServer', '')
        # Lógica para leer archivo del file server
        return ""