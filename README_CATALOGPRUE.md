## Catalogador pruebas v1

Este codigo contiene 2 lenguajes en principio, PowerShell y Python. Otras tecnologias como PowerAutomate, ChatGPT, API´s. 

El objetivo es abarcar todas las tareas del catalogador, en esta version solo estan las de: 

- **Promocion a pruebas incidentes y Direccion de aplicaciones**
- **Aplicacion en pruebas incidentes y Direccion de aplicaciones**
- **Actualizacion de archivos**

Faltarian: 

- **Confirmacion de aplicacion**
- **Devolucion de aplicacion**

En la carpeta de **"Documentacion"** se encontrara la logica desarrollada para estos codigos, donde se deja en claro del flujo de estos codigos y que funcionen cumplen, de esta manera si se desea hacer una correccion
se tiene la base de esa logica creada

## La estructura del proyecto 

````txt
C:\Bancolombia\CatalogadorAuto\
├── 📄 Documentación\
│   ├── 📋 Manual_Usuario.md
│   ├── 🔧 Manual_Tecnico.md
│   └── 📊 KPIs_Metricas.md
│
├── 🔧 Scripts\                          # ✅ TODOS LOS SCRIPTS AQUÍ
│   ├── 🚀 main_orchestrator.ps1         # Script principal
│   ├── 📸 screenshot_handler.ps1        # Manejo de "capturas"
│   ├── 📁 file_operations.ps1           # Operaciones de archivo
│   ├── 📊 status_tracker.ps1            # Seguimiento de estado
│   ├── 🏗️ setup_environment.ps1         # Configuración inicial
│   ├── 🔐 config_permisos.ps1           # Configura permisos
│   ├── ⚙️ config_variables_entorno.ps1  # Variables de entorno
│   ├── 📈 dashboard_monitoreo.ps1       # Dashboard de métricas
│   ├── 🚀 deploy_catalogador.ps1        # Despliegue
│   ├── 🧪 test_components.ps1           # Pruebas unitarias
│   ├── 🔗 test_integracion.ps1          # Pruebas integración
│   └── 📧 notificaciones.ps1            # Sistema de alertas
│
├── 📊 Logs\                             # ✅ TODOS LOS LOGS AQUÍ
│   ├── 📋 execution_YYYYMMDD.log        # Logs de ejecución
│   ├── 🔧 operations.log                # Operaciones detalladas
│   ├── 📸 Screenshots\                  # "Capturas" en texto
│   │   └── paso1_20231201_143022.txt
│   ├── 🚨 Errores\                      # Logs de errores
│   │   └── error_copia_20231201_143025.txt
│   ├── 📍 Estados\                      # Estados en tiempo real
│   │   └── CATALOG_20231201143022.status
│   ├── 👁️ Auditoria\                   # Logs de auditoría
│   └── 📄 Reportes\                     # Reportes generados
│       ├── execution_report_CATALOG_20231201143022.txt
│       └── error_report_CATALOG_20231201143025.txt
│
├── 💾 Backups\                          # ✅ BACKUPS AQUÍ
│   ├── 📅 Diarios\
│   ├── 📆 Semanales\
│   └️── 📅 Mensuales\
│
├── 🗑️ Temp\                             # Archivos temporales
├── 🔄 Cache\                            # Cache del sistema
└── 📁 Config\                           # Archivos de configuración
    ├── ⚙️ config_alertas.json
    ├️── 🔧 config_azure_devops.json
    └── 📊 config_metricas.json
````

Hay 2 ejecutables ps1 los cuales son: **logs_maintenace** y **setup_evironment**
Los cuales cumplen las siguientes funciones: 

#### logs_maintenace

Mantenimiento de los logs del proyecto, se deben usar en caso de sobrecarga o fallos en los logs

#### setup_evironment

Creacion de la estructura del proyecto
