import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import re
import os

class IAHandler:
    def __init__(self):
        self.vectorizer = TfidfVectorizer()
    
    def analizar_control_pasos(self, control_pasos_data):
        """IA analiza control de pasos y manual técnico"""
        
        analisis = {
            "coincidencias_codigo": self._comparar_codigos(
                control_pasos_data['azure']['codigo'],
                control_pasos_data['file_server']['codigo']
            ),
            "parametrizacion_consistente": self._validar_parametrizacion(
                control_pasos_data['azure']['parametrizacion'],
                control_pasos_data['file_server']['parametrizacion']
            ),
            "objetos_consistentes": self._comparar_objetos(
                control_pasos_data['azure']['objetos'],
                control_pasos_data['file_server']['objetos']
            ),
            "clases_detectadas": self._detectar_clases(control_pasos_data['file_server']['objetos']),
            "recomendaciones": self._analizar_recomendaciones(control_pasos_data['file_server']['recomendaciones'])
        }
        
        return analisis
    
    def obtener_rutas(self, control_pasos_data):
        """IA extrae rutas de desarrollo y pruebas"""
        # Analizar texto para encontrar rutas
        texto = control_pasos_data['file_server']['contenido']
        
        rutas = {
            "desarrollo": self._extraer_ruta_desarrollo(texto),
            "pruebas": self._extraer_ruta_pruebas(texto)
        }
        
        return rutas
    
    def verificar_dependencias(self, work_item_id, ruta_pruebas):
        """IA verifica dependencias de otros soportes"""
        
        # Analizar recomendaciones para encontrar dependencias
        dependencias = self._extraer_dependencias(ruta_pruebas)
        
        return {
            "tiene_dependencias": len(dependencias) > 0,
            "dependencias": dependencias,
            "recomendacion": self._generar_recomendacion_dependencias(dependencias)
        }
    
    def analizar_cambios(self, work_item_id):
        """IA analiza cambios para actualización"""
        
        cambios = {
            "archivos_modificados": self._detectar_archivos_modificados(work_item_id),
            "impacto": self._calcular_impacto(work_item_id),
            "ruta_desarrollo": self._obtener_ruta_desarrollo_actual(work_item_id),
            "ruta_pruebas": self._obtener_ruta_pruebas_actual(work_item_id)
        }
        
        return cambios
    
    def _comparar_codigos(self, codigo_azure, codigo_file_server):
        """Compara códigos usando similitud de texto"""
        try:
            similitud = cosine_similarity(
                self.vectorizer.fit_transform([codigo_azure, codigo_file_server])
            )[0][1]
            return similitud > 0.9
        except:
            return codigo_azure == codigo_file_server
    
    def _validar_parametrizacion(self, parametrizacion_azure, parametrizacion_file_server):
        """Valida consistencia en parametrización"""
        return parametrizacion_azure == parametrizacion_file_server
    
    def _comparar_objetos(self, objetos_azure, objetos_file_server):
        """Compara listas de objetos usando IA"""
        # Usar similitud de texto para comparar nombres
        coincidencias = 0
        for obj_azure in objetos_azure:
            for obj_file in objetos_file_server:
                if self._calcular_similitud_texto(obj_azure, obj_file) > 0.8:
                    coincidencias += 1
                    break
        
        return coincidencias == len(objetos_azure)
    
    def _detectar_clases(self, objetos):
        """Detecta archivos .CLASS en objetos"""
        clases = []
        for objeto in objetos:
            if '.class' in objeto.lower():
                clases.append(objeto)
        return clases
    
    def _analizar_recomendaciones(self, recomendaciones):
        """IA analiza recomendaciones para encontrar dependencias"""
        dependencias = []
        
        # Buscar patrones como "Debe estar aplicado el soporte X"
        patrones = [
            r"debe estar aplicado el soporte (\w+)",
            r"depende del soporte (\w+)",
            r"requiere el soporte (\w+)"
        ]
        
        for patron in patrones:
            coincidencias = re.findall(patron, recomendaciones, re.IGNORECASE)
            dependencias.extend(coincidencias)
        
        return dependencias
    
    def _calcular_similitud_texto(self, texto1, texto2):
        """Calcula similitud entre dos textos"""
        try:
            vector = self.vectorizer.fit_transform([texto1, texto2])
            return cosine_similarity(vector[0:1], vector[1:2])[0][0]
        except:
            return 0.0