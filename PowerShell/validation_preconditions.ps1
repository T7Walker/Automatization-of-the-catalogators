# validacion_precondicion.ps1

function Test-PrecondicionAmbiente {
    param(
        [hashtable]$ControlPasos,
        [string]$AmbienteDestino
    )
    
    try {
        Write_OperationLog -Operation "VALIDACION_PRECONDICION" -Details "Verificando precondición para ambiente: $AmbienteDestino" -Status "INFO"
        
        # 1. OBTENER TEXTO DE RECOMENDACIONES DEL CONTROL DE PASOS
        $textoRecomendaciones = $ControlPasos.RecomendacionesProcesos
        
        if ([string]::IsNullOrEmpty($textoRecomendaciones)) {
            Write_OperationLog -Operation "VALIDACION_PRECONDICION" -Details "No hay texto en recomendaciones" -Status "WARNING"
            return $true  # Si no hay texto, no hay precondición que validar
        }
        
        # 2. BUSCAR PATRÓN "Debe estar aplicado el soporte {X}"
        $patron = "Debe estar aplicado el soporte (.+)"
        $coincidencias = [regex]::Matches($textoRecomendaciones, $patron)
        
        if ($coincidencias.Count -eq 0) {
            Write_OperationLog -Operation "VALIDACION_PRECONDICION" -Details "No se encontró patrón de precondición" -Status "INFO"
            return $true  # No hay precondición específica
        }
        
        # 3. VERIFICAR CADA SOPORTE MENCIONADO
        foreach ($coincidencia in $coincidencias) {
            $nombreSoporte = $coincidencia.Groups[1].Value.Trim()
            Write_OperationLog -Operation "VALIDACION_PRECONDICION" -Details "Verificando soporte: $nombreSoporte" -Status "INFO"
            
            # VERIFICAR SI EL SOPORTE ESTÁ APLICADO EN EL AMBIENTE DESTINO
            $soporteAplicado = Test-SoporteAplicado -NombreSoporte $nombreSoporte -Ambiente $AmbienteDestino
            
            if (!$soporteAplicado) {
                Write_OperationLog -Operation "VALIDACION_PRECONDICION" -Details "SOPORTE NO APLICADO: $nombreSoporte en $AmbienteDestino" -Status "FAILED"
                
                # ACTIVAR POWER AUTOMATE PARA NOTIFICAR CATALOGADORES
                Invoke-PowerAutomateNotificacion -Tipo "PRECONDICION_NO_CUMPLIDA" -Soporte $nombreSoporte -Ambiente $AmbienteDestino -WorkItemId $ControlPasos.WorkItemId -Destinatarios @("catalogadores@bancolombia.com")
                
                return $false
            }
            
            Write_OperationLog -Operation "VALIDACION_PRECONDICION" -Details "Soporte aplicado: $nombreSoporte" -Status "COMPLETED"
        }
        
        return $true
    }
    catch {
        Write_OperationLog -Operation "VALIDACION_PRECONDICION" -Details "Error validando precondición: $($_.Exception.Message)" -Status "FAILED"
        return $false
    }
}

function Test-SoporteAplicado {
    param(
        [string]$NombreSoporte,
        [string]$Ambiente
    )
    
    # LÓGICA PARA VERIFICAR SI UN SOPORTE ESTÁ APLICADO EN UN AMBIENTE
    # Esto depende de tu sistema de gestión de soportes
    
    # EJEMPLO: Consultar base de datos o API de soportes
    try {
        # $soportesAplicados = Get-SoportesAplicados -Ambiente $Ambiente
        # return $soportesAplicados -contains $NombreSoporte
        
        # Por ahora retornamos true para pruebas
        return $true
    }
    catch {
        Write_OperationLog -Operation "TEST_SOPORTE_APLICADO" -Details "Error verificando soporte: $($_.Exception.Message)" -Status "FAILED"
        return $false
    }
}

Export-ModuleMember -Function Test-PrecondicionAmbiente, Test-SoporteAplicado