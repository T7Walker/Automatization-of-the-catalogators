import subprocess
import json
import os
from ia_handler import IAHandler
from azure_handler import AzureHandler
from powerautomate_interface import PowerAutomateInterface

class CatalogadorAutomatico:
    def __init__(self):
        self.ia_handler = IAHandler()
        self.azure_handler = AzureHandler()
        self.power_automate = PowerAutomateInterface()
    
    def ejecutar_promocion_pruebas(self, work_item_id):
        """Paso 1-6: Promoción a Pruebas"""
        print(f"🚀 INICIANDO PROMOCIÓN: {work_item_id}")
        
        try:
            # Paso 1: Obtener dirección de atención
            direccion_atencion = self.azure_handler.obtener_direccion_atencion(work_item_id)
            print(f"📍 Dirección de atención: {direccion_atencion}")
            
            # Paso 2: Obtener y analizar control de pasos FM-169
            control_pasos_data = self.azure_handler.obtener_control_pasos(work_item_id)
            
            # Paso 2.1-2.2: IA analiza documentos
            analisis_ia = self.ia_handler.analizar_control_pasos(control_pasos_data)
            
            # Ejecutar validaciones críticas via PowerShell
            validacion_result = self._ejecutar_powershell_severidad(
                "PROMOCION", work_item_id, control_pasos_data
            )
            
            if not validacion_result["exitoso"]:
                self._manejar_error(validacion_result["errores"], work_item_id, direccion_atencion)
                return False
            
            # Paso 3-4: Copiar desarrollo → pruebas
            rutas = self.ia_handler.obtener_rutas(control_pasos_data)
            operacion_archivos = self._ejecutar_powershell_operaciones(
                rutas["desarrollo"], rutas["pruebas"], work_item_id
            )
            
            if not operacion_archivos:
                raise Exception("Error en operaciones de archivo")
            
            # Paso 5: Actualizar estado en Azure DevOps
            self.azure_handler.actualizar_estado(work_item_id, "Testing")
            
            # Paso 6: Notificación final
            mensaje = self._generar_mensaje_exito(work_item_id, rutas["pruebas"])
            self._ejecutar_powershell_notificacion("COMPLETADO", [mensaje], "PROMOCION", work_item_id)
            
            print("✅ PROMOCIÓN COMPLETADA EXITOSAMENTE")
            return True
            
        except Exception as e:
            print(f"❌ ERROR EN PROMOCIÓN: {str(e)}")
            self._manejar_error([str(e)], work_item_id, direccion_atencion)
            return False
    
    def ejecutar_aplicacion_pruebas(self, work_item_id):
        """Aplicación en Pruebas"""
        print(f"📦 INICIANDO APLICACIÓN: {work_item_id}")
        
        try:
            # Paso 1: Obtener dirección de atención
            direccion_atencion = self.azure_handler.obtener_direccion_atencion(work_item_id)
            
            # Paso 2: Obtener ruta de pruebas
            ruta_pruebas = self.azure_handler.obtener_ruta_pruebas(work_item_id)
            
            # Paso 3: IA verifica dependencias
            dependencias = self.ia_handler.verificar_dependencias(work_item_id, ruta_pruebas)
            
            if dependencias["tiene_dependencias"]:
                self._manejar_dependencias(dependencias, work_item_id)
                return False
            
            # Paso 4-5: Crear tarea de aplicación
            tarea_aplicacion = self.power_automate.crear_tarea_aplicacion(
                work_item_id, ruta_pruebas, direccion_atencion
            )
            
            print("✅ APLICACIÓN PROGRAMADA")
            return True
            
        except Exception as e:
            print(f"❌ ERROR EN APLICACIÓN: {str(e)}")
            self._manejar_error([str(e)], work_item_id, direccion_atencion)
            return False
    
    def ejecutar_actualizacion_archivos(self, work_item_id):
        """Actualización de Archivos"""
        print(f"🔄 INICIANDO ACTUALIZACIÓN: {work_item_id}")
        
        try:
            # Paso 1: IA analiza cambios
            cambios = self.ia_handler.analizar_cambios(work_item_id)
            
            # Paso 2: PowerShell ejecuta actualización
            resultado_actualizacion = self._ejecutar_powershell_actualizacion(
                cambios["ruta_desarrollo"], cambios["ruta_pruebas"], work_item_id
            )
            
            if not resultado_actualizacion:
                raise Exception("Error en actualización de archivos")
            
            # Paso 3: Subir registro a Azure DevOps
            registro_cambios = self._generar_registro_cambios(cambios)
            self.azure_handler.subir_adjunto(work_item_id, registro_cambios)
            
            # Paso 4-5: Notificaciones
            self.power_automate.notificar_actualizacion_completada(work_item_id)
            
            print("✅ ACTUALIZACIÓN COMPLETADA")
            return True
            
        except Exception as e:
            print(f"❌ ERROR EN ACTUALIZACIÓN: {str(e)}")
            self._manejar_error([str(e)], work_item_id, "N/A")
            return False
    
    def _ejecutar_powershell_severidad(self, tipo_proceso, work_item_id, control_pasos):
        """Ejecuta validaciones críticas via PowerShell"""
        try:
            script_path = r"C:\Bancolombia\CatalogadorAuto\PowerShell\sistema_severidad_actualizado.ps1"
            
            result = subprocess.run([
                "powershell", "-File", script_path,
                "-TipoProceso", tipo_proceso,
                "-WorkItemId", work_item_id,
                "-ControlPasos", json.dumps(control_pasos)
            ], capture_output=True, text=True, encoding='utf-8')
            
            if result.returncode == 0:
                return json.loads(result.stdout)
            else:
                return {"exitoso": False, "errores": [result.stderr]}
                
        except Exception as e:
            return {"exitoso": False, "errores": [f"Error PowerShell: {str(e)}"]}
    
    def _ejecutar_powershell_operaciones(self, source, destination, work_item_id):
        """Ejecuta operaciones de archivo via PowerShell"""
        try:
            script_path = r"C:\Bancolombia\CatalogadorAuto\PowerShell\file_operations.ps1"
            
            result = subprocess.run([
                "powershell", "-File", script_path,
                "-Source", source,
                "-Destination", destination,
                "-WorkItemId", work_item_id
            ], capture_output=True, text=True, encoding='utf-8')
            
            return result.returncode == 0
            
        except Exception as e:
            print(f"Error operaciones archivo: {e}")
            return False
    
    def _ejecutar_powershell_notificacion(self, severidad, mensajes, tipo_proceso, work_item_id):
        """Ejecuta notificaciones via PowerShell"""
        try:
            script_path = r"C:\Bancolombia\CatalogadorAuto\PowerShell\sistema_notificaciones.ps1"
            
            result = subprocess.run([
                "powershell", "-File", script_path,
                "-Severidad", severidad,
                "-Mensajes", json.dumps(mensajes),
                "-TipoProceso", tipo_proceso,
                "-WorkItemId", work_item_id
            ], capture_output=True, text=True, encoding='utf-8')
            
            return result.returncode == 0
            
        except Exception as e:
            print(f"Error notificación: {e}")
            return False
    
    def _manejar_error(self, errores, work_item_id, direccion_atencion):
        """Manejo centralizado de errores"""
        # Tomar screenshot via PowerShell
        self._ejecutar_powershell_screenshot(work_item_id, "ERROR")
        
        # Notificar via PowerShell
        self._ejecutar_powershell_notificacion("ALTA", errores, "ERROR", work_item_id)
        
        # Comentar en Azure DevOps
        mensaje_error = self._generar_mensaje_error(errores, direccion_atencion)
        self.azure_handler.agregar_comentario(work_item_id, mensaje_error)
    
    def _generar_mensaje_exito(self, work_item_id, ruta_pruebas):
        """Genera mensaje de éxito para notificación"""
        return f"""
{{etiquetar a juan Felipe y control de requerimientos}}
Cordial saludo

Se informa que el soporte {work_item_id} se encuentra en pruebas a espera de su
solicitud de aplicación
Por favor confirmar la fecha y ambiente de aplicación

RUTA: {ruta_pruebas}

¡Muchas Gracias!
"""