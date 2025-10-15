# config.py - CONFIGURACIÓN PARA BANCO MUNDO MUJER (BMM)
import os

# Configuración Azure DevOps
AZURE_DEVOPS_CONFIG = {
    'organizacion': os.getenv('AZURE_DEVOPS_ORG', 'bmm-organizacion'),
    'proyecto': os.getenv('AZURE_DEVOPS_PROJECT', 'bmm-proyecto'),
    'token': os.getenv('AZURE_DEVOPS_TOKEN', 'tu-token-bmm')
}

# Configuración Power Automate
POWER_AUTOMATE_CONFIG = {
    'flujos': {
        'crear_tarea_aplicacion': os.getenv('POWER_AUTOMATE_APLICACION_URL_BMM', ''),
        'notificacion_actualizacion': os.getenv('POWER_AUTOMATE_ACTUALIZACION_URL_BMM', ''),
        'notificacion_error': os.getenv('POWER_AUTOMATE_ERROR_URL_BMM', '')
    }
}

# Configuración rutas BMM
PATHS_CONFIG = {
    'scripts_python': r"C:\BMM\CatalogadorAuto\Python",
    'scripts_powershell': r"C:\BMM\CatalogadorAuto\PowerShell",
    'logs': r"C:\BMM\CatalogadorAuto\Logs",
    'backups': r"C:\BMM\CatalogadorAuto\Backups"
}

# Configuración específica BMM
BMM_CONFIG = {
    'empresa': 'Banco Mundo Mujer',
    'abreviatura': 'BMM',
    'emails_soporte': [
        'soporte.tecnico@bmm.com.co',
        'desarrolladores@bmm.com.co',
        'catalogadores@bmm.com.co'
    ],
    'equipos_soporte': {
        'infraestructura': 'equipo.infraestructura@bmm.com.co',
        'desarrollo': 'equipo.desarrollo@bmm.com.co',
        'calidad': 'equipo.calidad@bmm.com.co'
    }
}

# Configuración IA para BMM
IA_CONFIG = {
    'modelo_validacion': 'modelos/modelo_validacion_bmm.pkl',
    'umbral_confianza': 0.8,
    'patrones_bmm': [
        'bmm', 'mundomujer', 'bancomundomujer'
    ]
}