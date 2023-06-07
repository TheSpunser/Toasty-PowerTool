#-------[Initialisations]-------

# Init PowerShell Gui-related assemblies
Add-Type -AssemblyName PresentationFramework, System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()
    
#-------[Form]-------

function MainPrompt {

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Toasty's PowerTools"
$Form

}

#-------[Functions]-------

##   ---   TO DO   ---   ##

    #   Get LAPS Password
    $UAD = $null # Temp Param
    $wshell = New-Object -ComObject Wscript.shell
    $creds = Get-Credential -UserName "AWC_DOMAIN\_" -Message "Enter Creds"
    try {$Pass = Get-LapsADPassword -Identity $UAD -DomainController AWV-WAD-S-DC01 -DecryptionCredential $creds -Credential $creds -AsPlainText | Select-Object Password -ExpandProperty Password }
    catch [Microsoft.Windows.LAPS.GetLapsADPassword] {
        "UAD not Present in AD"
    }
    #$Pass
    
    if (!($Pass -eq $null)) {
        $wshell.Popup("LAPS Password: $Pass",0,"Done",0x1)
    }else{
        Catch {
            $wshell.Popup("UAD Not Present in LAPS DB! Possibly Fallen Off the Domain.",0,"Error",0x1)
        }
    }
    

    #   Open Powershell ISE as Admin

    Start-Process Powershell_ISE -Verb RunAs

    #   Open CMD as Admin

    Start-Process CMD -Verb RunAs

    #   Remote Desktop

    mstsc /v:$UAD /f

    #   Restart UAD Remotely

    Restart-Computer -ComputerName $UAD -Credential $creds -Force

    #   Open CCM02 Deployment Share

    Start-Process explorer -ArgumentList "\\AWV-WAD-S-CCM02\Deployment Share"

    #   Install RSATT Tools (Possiblility of remote install?)

    Copy-Item -Path "\\AWV-WAD-S-UTL01\CSF Utils\Software Library\RSATTools" -Recurse -Destination "\\$UAD\D$" -Force -Credential $creds
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

    Start-Process MSEdge.exe -ArgumentList "http://awv-wad-s-hlx04.awc.mod1.gb:8080/smartit/app/#/ticket-console"

    #   Open CSF Utils Drive

    Start-Process explorer -ArgumentList "\\AWV-WAD-S-UTL01\CSF Utils"

    #   Push Group Policy Update

    Invoke-GPUpdate -Computer $UAD -Force

    #   Push Group Policy Update on remote UAD

    Invoke-GPUpdate -Computer $UAD -Force

    #   Uninstall specified software


    #   Uninstall specified software on remote UAD


    #   Perform Profile Reset


    #   Force Windows Update

    Invoke-Command -ComputerName $UAD -Credential $creds -ScriptBlock { 

        $check = Get-Service -Name wuauserv | Select-Object Status -ExpandProperty Status

        if ($check.ToString() -eq 'Stopped') {
            Set-Service -Name wuauserv -StartupType Disabled
        }
        elseif ($check.ToString() -eq 'Running' -or $check.ToString() -eq 'Stopping') {
            Stop-Service -Name wuauserv -Force
            Set-Service -Name wuauserv -StartupType Disabled
        }

        Remove-Item -Path "C:\Windows\SoftwareDistribution" -Recurse -Confirm:$false -Force
        Start-Service -Name wuauserv
        Set-Service -Name wuauserv -StartupType Automatic
     }

    #   Copy User's D drive to CSF Utils
    $UAD = "AWM-WAD-S-718" # Temp Param
    New-PSDrive -Name "DriveCopy" -PSProvider FileSystem -Root "\\$UAD\D$" -Credential $creds
    Start-Sleep -Seconds 5
    $Path = Get-PSDrive -Name DriveCopy | Select-Object Root -ExpandProperty Root
    Copy-Item -Path $Path -Recurse -Destination "\\awv-wad-s-utl01\CSF Utils\IS Team\D Drives\$UAD" -Force


#-------[Script]-------

[void]$Form.ShowDialog()