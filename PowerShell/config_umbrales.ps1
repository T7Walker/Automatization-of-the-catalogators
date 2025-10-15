# config_umbrales.ps1

$UmbralesTiempo = @{
    "PROMOCION"   = 15    # minutos
    "APLICACION"  = 5     # minutos  
    "ACTUALIZACION" = 10  # minutos
}

$ReglasNotificacion = @{
    "CRITICA" = @{
        Accion = "CERRAR_CICLO"
        Destinatarios = @("catalogadores@bancolombia.com", "desarrolladores@bancolombia.com")
        PowerAutomate = $true
    }
    "ALTA" = @{
        Accion = "NOTIFICAR_CATALOGADORES" 
        Destinatarios = @("catalogadores@bancolombia.com")
        PowerAutomate = $true
    }
    "MEDIA" = @{
        Accion = "ETIQUETAR_LIDER_DESARROLLADOR"
        Destinatarios = @("lider_desarrollo@bancolombia.com", "desarrollador_asignado@bancolombia.com")
        PowerAutomate = $false
        AzureDevOps = $true
    }
    "BAJA" = @{
        Accion = "ETIQUETAR_LIDER_DESARROLLADOR"
        Destinatarios = @("lider_desarrollo@bancolombia.com", "desarrollador_asignado@bancolombia.com") 
        PowerAutomate = $false
        AzureDevOps = $true
    }
}

Export-ModuleMember -Variable UmbralesTiempo, ReglasNotificacion