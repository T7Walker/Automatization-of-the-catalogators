# control_pasos_validator.py
import re

class ControlPasosValidator:
    def __init__(self):
        self.patrones_validacion = {
            'codigo_control_paso': r'FM-169-\d+',
            'parametrizacion': r'^[MN]$',
            'objeto_class': r'.*\.class$',
            'objeto_bmm': r'.*bmm.*'
        }
    
    def validar_control_pasos_completo(self, control_pasos_data):
        """Valida integridad del control de pasos"""
        validaciones = {
            'codigo_valido': self._validar_codigo(control_pasos_data),
            'parametrizacion_valida': self._validar_parametrizacion(control_pasos_data),
            'objetos_consistentes': self._validar_objetos_consistentes(control_pasos_data),
            'rutas_presentes': self._validar_rutas(control_pasos_data)
        }
        
        return {
            'valido': all(validaciones.values()),
            'detalles': validaciones,
            'errores': self._obtener_errores(validaciones)
        }
    
    def _validar_codigo(self, control_pasos_data):
        """Valida formato del código de control de pasos"""
        codigo_azure = control_pasos_data['azure']['codigo']
        codigo_file_server = control_pasos_data['file_server']['codigo']
        
        formato_valido = bool(re.match(self.patrones_validacion['codigo_control_paso'], codigo_azure))
        coinciden = codigo_azure == codigo_file_server
        
        return formato_valido and coinciden
    
    def _validar_parametrizacion(self, control_pasos_data):
        """Valida consistencia de parametrización"""
        parametrizacion_azure = control_pasos_data['azure']['parametrizacion']
        parametrizacion_file_server = control_pasos_data['file_server']['parametrizacion']
        
        azure_valida = bool(re.match(self.patrones_validacion['parametrizacion'], parametrizacion_azure))
        file_server_valida = bool(re.match(self.patrones_validacion['parametrizacion'], parametrizacion_file_server))
        coinciden = parametrizacion_azure == parametrizacion_file_server
        
        return azure_valida and file_server_valida and coinciden
    
    def _validar_objetos_consistentes(self, control_pasos_data):
        """Valida que los objetos sean consistentes entre Azure y File Server"""
        objetos_azure = set(control_pasos_data['azure']['objetos'])
        objetos_file_server = set(control_pasos_data['file_server']['objetos'])
        
        return objetos_azure == objetos_file_server
    
    def _validar_rutas(self, control_pasos_data):
        """Valida que las rutas estén presentes"""
        ruta_desarrollo = control_pasos_data['azure']['ruta_desarrollo']
        ruta_pruebas = control_pasos_data['azure']['ruta_pruebas']
        
        return bool(ruta_desarrollo and ruta_pruebas)
    
    def _obtener_errores(self, validaciones):
        """Obtiene lista de errores de validación"""
        errores = []
        
        if not validaciones['codigo_valido']:
            errores.append("Código de control de pasos inválido o no coincide")
        
        if not validaciones['parametrizacion_valida']:
            errores.append("Parametrización inválida o no coincide")
        
        if not validaciones['objetos_consistentes']:
            errores.append("Los objetos no coinciden entre Azure y File Server")
        
        if not validaciones['rutas_presentes']:
            errores.append("Rutas de desarrollo/pruebas no configuradas")
        
        return errores