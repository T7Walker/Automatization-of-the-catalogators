# file_operations.py
import subprocess
import json
import os

class FileOperations:
    def __init__(self):
        self.powershell_scripts_path = r"C:\Bancolombia\CatalogadorAuto\PowerShell"
    
    def ejecutar_operacion_archivos(self, operacion, parametros):
        """Ejecuta operaciones de archivo via PowerShell"""
        script_map = {
            'copiar_desarrollo_pruebas': 'file_operations.ps1',
            'validar_estructura': 'file_operations.ps1',
            'crear_backup': 'file_operations.ps1'
        }
        
        script_name = script_map.get(operacion)
        if not script_name:
            raise ValueError(f"Operación no soportada: {operacion}")
        
        script_path = os.path.join(self.powershell_scripts_path, script_name)
        
        # Construir comando PowerShell
        cmd = [
            "powershell", "-File", script_path,
            "-Operacion", operacion
        ]
        
        # Agregar parámetros adicionales
        for key, value in parametros.items():
            cmd.extend([f"-{key}", str(value)])
        
        # Ejecutar
        result = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8')
        
        if result.returncode == 0:
            return {'exitoso': True, 'salida': result.stdout}
        else:
            return {'exitoso': False, 'error': result.stderr}
    
    def coordinar_copia_archivos(self, source, destination, work_item_id):
        """Coordina la copia de desarrollo a pruebas"""
        parametros = {
            'Source': source,
            'Destination': destination,
            'WorkItemId': work_item_id
        }
        
        return self.ejecutar_operacion_archivos('copiar_desarrollo_pruebas', parametros)