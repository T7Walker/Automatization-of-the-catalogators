# notificacion_handler.py
import subprocess
import json
import os
from powerautomate_interface import PowerAutomateInterface

class NotificacionHandler:
    def __init__(self):
        self.power_automate = PowerAutomateInterface()
        self.powershell_scripts_path = r"C:\Bancolombia\CatalogadorAuto\PowerShell"
    
    def enviar_notificacion(self, tipo, work_item_id, datos_adicionales=None):
        """Envía notificación según el tipo"""
        handlers = {
            'error_validacion': self._notificar_error_validacion,
            'promocion_completada': self._notificar_promocion_completada,
            'aplicacion_programada': self._notificar_aplicacion_programada,
            'actualizacion_completada': self._notificar_actualizacion_completada
        }
        
        handler = handlers.get(tipo)
        if handler:
            return handler(work_item_id, datos_adicionales or {})
        else:
            raise ValueError(f"Tipo de notificación no soportado: {tipo}")
    
    def _notificar_error_validacion(self, work_item_id, datos):
        """Notifica error de validación"""
        # Usar PowerShell para screenshot
        self._ejecutar_powershell_screenshot(work_item_id, "ERROR_VALIDACION")
        
        # Usar Power Automate para notificación
        return self.power_automate.notificar_error(
            work_item_id, 
            datos.get('errores', []), 
            datos.get('direccion_atencion', '')
        )
    
    def _notificar_promocion_completada(self, work_item_id, datos):
        """Notifica promoción completada"""
        # Usar PowerShell para notificación en Azure DevOps
        script_path = os.path.join(self.powershell_scripts_path, 'sistema_notificaciones.ps1')
        
        cmd = [
            "powershell", "-File", script_path,
            "-Severidad", "COMPLETADO",
            "-Mensajes", json.dumps([f"Promoción {work_item_id} completada"]),
            "-TipoProceso", "PROMOCION",
            "-WorkItemId", work_item_id
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8')
        return result.returncode == 0
    
    def _notificar_aplicacion_programada(self, work_item_id, datos):
        """Notifica aplicación programada"""
        return self.power_automate.crear_tarea_aplicacion(
            work_item_id,
            datos.get('ruta_pruebas', ''),
            datos.get('direccion_atencion', '')
        )
    
    def _notificar_actualizacion_completada(self, work_item_id, datos):
        """Notifica actualización completada"""
        return self.power_automate.notificar_actualizacion_completada(work_item_id)
    
    def _ejecutar_powershell_screenshot(self, work_item_id, contexto):
        """Ejecuta PowerShell para tomar screenshot"""
        script_path = os.path.join(self.powershell_scripts_path, 'screenshot_handler.ps1')
        
        cmd = [
            "powershell", "-File", script_path,
            "-Context", contexto,
            "-WorkItemId", work_item_id
        ]
        
        subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8')