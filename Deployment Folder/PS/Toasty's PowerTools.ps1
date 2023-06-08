#-------[Initialisations]-------

# Init PowerShell Gui-related assemblies
Add-Type -AssemblyName PresentationFramework, System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()
    
#-------[Form]-------

 # - - - XAML REFERENCE GOES HERE - - - #

#-------[Functions]-------

    #   Get LAPS Password

    $Enc = "QQBXAFYALQBXAEEARAAtAFMALQBEAEMAMAAxAA=="
    $Bytes = [System.Convert]::FromBase64String($Enc)
    $Text = [System.Text.Encoding]::Unicode.GetString($Bytes)

    $UAD = $null # Temp Param
    $wshell = New-Object -ComObject Wscript.shell
    $creds = Get-Credential -UserName "AWC_DOMAIN\_" -Message "Enter Creds"
    try {$Pass = Get-LapsADPassword -Identity $UAD -DomainController $Text -DecryptionCredential $creds -Credential $creds -AsPlainText | Select-Object Password -ExpandProperty Password }
    catch [Microsoft.Windows.LAPS.GetLapsADPassword] {
        "UAD not Present in AD"
    }
    #$Pass

    #   Open Powershell ISE as Admin

    Start-Process Powershell_ISE -Verb RunAs

    #   Open CMD as Admin

    Start-Process CMD -Verb RunAs

    #   Remote Desktop

    mstsc /v:$UAD /f

    #   Restart UAD Remotely

    Get-Service -Name WinRM -ComputerName $UAD | Set-Service -Status Running | Set-Service -StartupType Automatic
    Restart-Computer -ComputerName $UAD -Credential $creds -Force

    #   Open CCM02 Deployment Share

    $Enc = "XABcAEEAVwBWAC0AVwBBAEQALQBTAC0AQwBDAE0AMAAyAFwARABlAHAAbABvAHkAbQBlAG4AdAAgAFMAaABhAHIAZQA="
    $Bytes = [System.Convert]::FromBase64String($Enc)
    $Text = [System.Text.Encoding]::Unicode.GetString($Bytes)

    Start-Process explorer -ArgumentList ($Text.ToString())

    #   Install RSATT Tools (Possiblility of remote install?)
    $Enc = "XABcAEEAVwBWAC0AVwBBAEQALQBTAC0AVQBUAEwAMAAxAFwAQwBTAEYAIABVAHQAaQBsAHMAXABTAG8AZgB0AHcAYQByAGUAIABMAGkAYgByAGEAcgB5AFwAUgBTAEEAVABUAG8AbwBsAHMA"
    $Bytes = [System.Convert]::FromBase64String($Enc)
    $Text = [System.Text.Encoding]::Unicode.GetString($Bytes)
    Copy-Item -Path $Text.ToString() -Recurse -Destination "\\$UAD\D$" -Force -Credential $creds
    Get-Service -Name WinRM -ComputerName $UAD | Set-Service -Status Running | Set-Service -StartupType Automatic
    Invoke-Command -ComputerName $UAD -Credential $creds -ScriptBlock { Get-WindowsCapability -Name RSAT* -Online -Source D:\RSATTools | Add-WindowsCapability -Online -Source D:\RSATTools }

    #   Open Registry

    Start-Process regedit -verb runas

    #   Ping UAD / Server

    $computerName = $pingE.Text
    $pingB.Text = "."
    $pingB.Text = ".."
    $pingB.Text = "..."

    if ([string]::IsNullOrEmpty($pingE.text)) {
        $info = New-Object -ComObject Wscript.shell
        $info.Popup("Enter an IP or Domain Name!",0,"Information",0+48)
        $pingB.Text = "Ping"
    } else {
        if (Test-Connection $computerName -quiet -Count 2){
            $pingL.Text = "$computerName Online"
            $pingL.ForeColor = '#5AFF47'
            $pingB.Text = "Ping"
        }
        else{
            $pingL.Text = "$computerName Offline"
            $pingL.ForeColor = '#FF0000'
            $pingB.Text = "Ping"
        }
    }

    #   Explore UAD File System

    Start-Process explorer -ArgumentList "\\$UAD\C$" -Credential $creds
    Start-Process explorer -ArgumentList "\\$UAD\D$" -Credential $creds

    #   Open Helix

    $Enc = "aAB0AHQAcAA6AC8ALwBhAHcAdgAtAHcAYQBkAC0AcwAtAGgAbAB4ADAANAAuAGEAdwBjAC4AbQBvAGQAMQAuAGcAYgA6ADgAMAA4ADAALwBzAG0AYQByAHQAaQB0AC8AYQBwAHAALwAjAC8AdABpAGMAawBlAHQALQBjAG8AbgBzAG8AbABlAA=="
    $Bytes = [System.Convert]::FromBase64String($Enc)
    $Text = [System.Text.Encoding]::Unicode.GetString($Bytes)

    Start-Process MSEdge.exe -ArgumentList $Text

    #   Open CSF Utils Drive

    $Enc = "XABcAEEAVwBWAC0AVwBBAEQALQBTAC0AVQBUAEwAMAAxAFwAQwBTAEYAIABVAHQAaQBsAHMA"
    $Bytes = [System.Convert]::FromBase64String($Enc)
    $Text = [System.Text.Encoding]::Unicode.GetString($Bytes)

    Start-Process explorer -ArgumentList $Text.ToString()

    #   Push Group Policy Update

    Get-Service -Name WinRM -ComputerName $UAD | Set-Service -Status Running | Set-Service -StartupType Automatic
    Invoke-GPUpdate -Computer $UAD -Force

    #   Uninstall specified software

    $app = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "*$inputApp*"}
    $app.Uninstall()

    #   Perform Profile Reset


    #   Force Windows Update

    Get-Service -Name WinRM -ComputerName $UAD | Set-Service -Status Running | Set-Service -StartupType Automatic
    Invoke-Command -ComputerName $UAD -Credential $creds -ScriptBlock { 

        $check = Get-Service -Name wuauserv | Select-Object Status -ExpandProperty Status

        if ($check.ToString() -eq 'Stopped') {
            Set-Service -Name wuauserv -Status Stopped -StartupType Disabled
        }
        elseif ($check.ToString() -eq 'Running' -or $check.ToString() -eq 'Stopping') {
            Set-Service -Name wuauserv -Status Stopped -StartupType Disabled
        }

        Remove-Item -Path "C:\Windows\SoftwareDistribution" -Recurse -Confirm:$false -Force
        Set-Service -Name wuauserv -StartupType Automatic -Status Running
     }

    #   Copy User's D drive to CSF Utils

    $Enc = "XABcAGEAdwB2AC0AdwBhAGQALQBzAC0AdQB0AGwAMAAxAFwAQwBTAEYAIABVAHQAaQBsAHMAXABJAFMAIABUAGUAYQBtAFwARAAgAEQAcgBpAHYAZQBzAA=="
    $Bytes = [System.Convert]::FromBase64String($Enc)
    $Text = [System.Text.Encoding]::Unicode.GetString($Bytes)

    $gdate = Get-Date -Format "yyyy-MM-dd HH-mm-ss"
    $date = $gdate.ToString()
    New-PSDrive -Name $date -PSProvider FileSystem -Root "\\$UAD\D$" -Credential $creds
    Start-Sleep -Seconds 5
    $Path = Get-PSDrive -Name DriveCopy | Select-Object Root -ExpandProperty Root
    Copy-Item -Path $Path -Recurse -Destination "'$Text'\'$UAD'" -Force
    Remove-PSDrive -Name $date -Confirm:$false


#-------[Script]-------

[void]$Form.ShowDialog()