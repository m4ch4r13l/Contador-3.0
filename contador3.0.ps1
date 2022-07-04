#Script para detectar dispositivos y contar las veces que se ha conectado

#Escondiendo ventana del PowerShell
#PowerShell.exe -windowstyle hidden{

#declarando las variables
$connect = 0
$inirialConnect = 0
$LP1Cell

Add-Type -AssemblyName PresentationFramework

function connect
{
    #Recorriendo el .txt para comprobar si el dispositivo deseado esta conectado en el pc
    $FILE = Get-Content "ids.txt"
    foreach ($LINE in $FILE) 
    {
        #Comprobando el nombre del dispositivo deseado
        if($LINE -eq "    Name: Mouse compatible con HID")
        {
            #Comprobando si el dispositivo ha sido detectado anteriormente
            if($global:connect -eq 0)
            {
                #Ejecutando la funcion "CellComparator"
                CellComparator
                #CounterPMBT
                Write-Output "Device Conect $LINE"

                #Cambiando el valor de $conect 
                $global:connect  = 1
            }
            else
            {
                Write-Output "The device is already connected"
            }
        }
    }
    if ($global:connect -eq 0)
    {
        Write-Output "Device is not connected"
    }
}

function CellComparator{

    <#
    cd C:\Debug

    $devices = cmd.exe /c adbml.exe devices -l

    cd 'C:\Users\2897583\Desktop\Device_Counter.mch-main\Device_Counter.mch-main 2.0'

    $LP1 = $devices | Select -Skip 1 | Select -First 1

    $LP2 = $devices | Select -Skip 3 | Select -First 1
    #>

    $LP1 = "G7W12HZusb                usb:Port_#0019.Hub_#0001     GVGTYHYH     UYTRTGT"
    $LP2 = "G7W12HZusb                usb:Port_#0025.Hub_#0001     GVGTYHYH     UYTRTGT"


    $LP1.Split(" ") | ForEach{
    
        if ($_ -eq "usb:Port_#0019.Hub_#0001"){
        
            $LP1Cell = 1
            CounterPMBT -cell $LP1Cell

        }
        if($_ -eq "usb:Port_#0025.Hub_#0001")
        {
        
            $LP1Cell = 2
            CounterPMBT -cell $LP1Cell
        
        }
    }

    $LP2.Split(" ") | ForEach{

        if ($_ -eq "usb:Port_#0019.Hub_#0001"){
        
            $LP2Cell = 1
            CounterPMBT -cell $LP2Cell

        }

        if($_ -eq "usb:Port_#0025.Hub_#0001")
        {
        
            $LP2Cell = 2
            CounterPMBT -cell $LP2Cell
    
        }
    }

}

function CounterPMBT
{

    param
    (
        $cell
    )

    $counterThermalPasteTXT  = Get-Content "Counter PMBT cell $cell.txt" | Select -First 2

    $counterThermalPasteTXT.Split(" ") | ForEach{
        $counterThermalPaste = $_
     }
    
    $counterSumaThermalPaste   = [int]$counterThermalPaste + 1

    Remove-Item -Path "Counter PMBT cell $cell.txt"
    Add-Content -Path "Counter PMBT cell $cell.txt" -Value "***COUNTER PMBT CELL $cell***"

    #Thermal Paste
    if ($counterSumaThermalPaste -ge 5)
    {
        $msgResp = [System.Windows.MessageBox]::Show('La pasta termica de la celda '+$cell+' a llegado a su limite de vida util, ¿Desea remplazarla?', 'ADVERTENCIA', 'YesNo','warning')
        
        switch ($msgResp)
        {
            'Yes' 
            {
                $counterThermalPasteTXT = "Counter Thermal Paste: 0"
    	        Add-Content -Path "Counter PMBT cell $cell.txt" -Value $counterThermalPasteTXT
            }
            'No' 
            {
    	        $counterThermalPasteTXT = "Counter Thermal Paste: $counterSumaThermalPaste"
    	        Add-Content -Path "Counter PMBT cell $cell.txt" -Value $counterThermalPasteTXT
            }
        }
    }
    else
    {
        $counterThermalPasteTXT = "Counter Thermal Paste: $counterSumaThermalPaste"
        Add-Content -Path "Counter PMBT cell $cell.txt" -Value $counterThermalPasteTXT
    }

}

Register-WmiEvent -Class Win32_DeviceChangeEvent -SourceIdentifier DeviceChangeEvent
write-host (get-date -format s) " Beginning script..."

#Creando lista de dispositivos conectados
cmd.exe /c devcon hwids * > ids.txt

do
{

    #declarando los eventos
    $newEvent = Wait-Event -SourceIdentifier DeviceChangeEvent
    $eventType = $newEvent.SourceEventArgs.NewEvent.EventType
    $eventTypeName = switch($eventType)
    {
        #definiendo los casos de los eventos
        1 {"Configuration changed"}
        2 {"Device arrival"}
        3 {"Device removal"}
        4 {"docking"}
    }

    write-host (get-date -format s) " Event detected = " $eventTypeName

    #Condicional al detectar el evento 2
    if($eventType -eq 1)
    {
    
        if($inirialConnect -eq 0)
        {
            #Creando lista de dispositivos conectados
            cmd.exe /c devcon hwids * > ids.txt
            Start-Sleep -Seconds 1
            connect
            $connect = 1
            $inirialConnect = 1
        }
    }
    elseif ($eventType -eq 2)
    {
        #Creando lista de dispositivos conectados
        cmd.exe /c devcon hwids * > ids.txt
        Start-Sleep -Seconds 1
        connect
    }
    #Condicional al detectar el caso 3
    elseif ($eventType -eq 3) 
    {
        cmd.exe /c devcon hwids * > ids.txt
        Start-Sleep -Seconds 1
        $FILE = Get-Content "ids.txt"
        foreach ($LINE in $FILE) 
        {
            if($LINE -eq "    Name: Mouse compatible con HID")
            {
                Write-Output "Device is still connected"
                $connect = 1
                Break
            }
            else
            {
                $connect = 0
            }
        }
        if ($connect -eq 0)
        {
            Write-Output "The device has been disconnected"
        }
    }

    Remove-Event -SourceIdentifier DeviceChangeEvent

    }

    while (1-eq1) #Loop until next event

    Unregister-Event -SourceIdentifier DeviceChangeEvent
#}
