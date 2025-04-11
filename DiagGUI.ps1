# Operating System Deployment
# Generic WinPE Diagnostics

#------------[Initialisation]------------

    # Init PowerShell Gui
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName PresentationFramework

#---------------[Form]-------------------

    # Create a new form
    $OSDLogUploadForm                    = New-Object system.Windows.Forms.Form

    # Define the size, title and background color
    $OSDLogUploadForm.ClientSize         = '500,200'
    $OSDLogUploadForm.text               = ""
    $OSDLogUploadForm.BackColor          = "#ffffff"
    $OSDLogUploadForm.FormBorderStyle    = 'FixedDialog'

    # Title Text
    $Title                           = New-Object system.Windows.Forms.Label
    $Title.text                      = "Upload SCCM OSD Logs"
    $Title.AutoSize                  = $true
    $Title.width                     = 25
    $Title.height                    = 10
    $Title.location                  = New-Object System.Drawing.Point(20,20)
    $Title.Font                      = 'Microsoft Sans Serif,13'

    # Description Text
    $Description                     = New-Object system.Windows.Forms.Label
    $Description.text                = "Click the Upload button below to upload OSD logs to ConfigMgr network share."
    $Description.AutoSize            = $true
    $Description.width               = 450
    $Description.height              = 50
    $Description.location            = New-Object System.Drawing.Point(20,50)
    $Description.Font                = 'Microsoft Sans Serif,10'

    # Upload Button
    $UploadBtn						= New-Object system.Windows.Forms.Button
    $UploadBtn.BackColor         	= "#a4ba67"
    $UploadBtn.text              	= "Upload"
    $UploadBtn.width             	= 90
    $UploadBtn.height            	= 30
    $UploadBtn.location          	= New-Object System.Drawing.Point(370,150)
    $UploadBtn.Font              	= 'Microsoft Sans Serif,10'
    $UploadBtn.ForeColor         	= "#ffffff"

    # Cancel Button
    $CancelBtn                       = New-Object system.Windows.Forms.Button
    $CancelBtn.BackColor             = "#ffffff"
    $CancelBtn.text                  = "Cancel"
    $CancelBtn.width                 = 90
    $CancelBtn.height                = 30
    $CancelBtn.location              = New-Object System.Drawing.Point(260,150)
    $CancelBtn.Font                  = 'Microsoft Sans Serif,10'
    $CancelBtn.ForeColor             = "#000"
    $CancelBtn.DialogResult          = [System.Windows.Forms.DialogResult]::Cancel

    # Shutdown Button
    $ShutdownBtn                       = New-Object system.Windows.Forms.Button
    $ShutdownBtn.BackColor             = "#ffffff"
    $ShutdownBtn.text                  = "Shutdown"
    $ShutdownBtn.width                 = 90
    $ShutdownBtn.height                = 30
    $ShutdownBtn.location              = New-Object System.Drawing.Point(50,150)
    $ShutdownBtn.Font                  = 'Microsoft Sans Serif,10'
    $ShutdownBtn.ForeColor             = "#000"

    # Add the elements to the form
    $OSDLogUploadForm.controls.AddRange(@($Title,$Description,$UploadBtn,$CancelBtn,$ShutdownBtn))

#------------[Functions]------------

    function UploadLogs {

        Write-Host "Mapping network share..."

        $Credential = Get-Credential
        New-SmbMapping -RemotePath \\sccm-smb.svc.ny.gov\PaaS_SCCM_SLOG -UserName $Credential.UserName -Password $Credential.GetNetworkCredential().Password
                Write-Host "Network share mapped."
        
        Write-Host "Testing network share connection..."
        IF (Test-Path 'FileSystem::\\') 
            {
                Write-Host "Connection to network share established."
                Get-CimInstance win32_bios | New-Item -Path "FileSystem::\\" -Name {$_.serialnumber} -ItemType "directory" -ErrorAction SilentlyContinue
                Write-Host "Folder created."

                IF (Get-PSDrive C)
                    {
                        # Creating and outputting log files to OSDTests directory
                            New-Item -Path "C:\Windows\Logs\" -Name "OSDTests" -ItemType Directory -ErrorAction Continue
                            ipconfig /all | Out-File C:\Windows\Logs\OSDTests\ipconfig.txt
                            ping dcs126pw3mp.svc.ny.gov | Out-File C:\Windows\Logs\OSDTests\ping.txt
                            Get-Date | Out-File C:\Windows\Logs\OSDTests\datetime.txt

                        # Copying log files to network share
                            Get-CimInstance win32_bios | Copy-Item C:\_SMSTaskSequence\Logs\* -Recurse -Destination {"\\" + $_.serialnumber} -ErrorAction SilentlyContinue
                            Get-CimInstance win32_bios | Copy-Item C:\Windows\Logs\* -Recurse -Destination {"\\" + $_.serialnumber} -ErrorAction SilentlyContinue
                            Get-CimInstance win32_bios | Copy-Item C:\Windows\CCM\Logs\* -Recurse -Destination {"\\" + $_.serialnumber} -ErrorAction SilentlyContinue
                        
                        Write-Host "Files uploaded to network share."
                        [System.Windows.MessageBox]::Show('Files were uploaded successfully.','Success','OK')
                    }
                    ELSE {
                        Write-Error -Exception "Unable to access C: drive."
                        [System.Windows.MessageBox]::Show('Unable to access C: drive.','Failed','OK','Error')
                    }
                
            } 

            ELSE {
                Write-Error "Unable to connect to network file share."
                [System.Windows.MessageBox]::Show('Unable to connect to network file share','Network Error','OK','Error')
            }

    
    }

    function ShutdownReboot {

        $ShutdownRebootForm                      = New-Object system.Windows.Forms.Form
        $ShutdownRebootForm.ClientSize           = '425,150'
        $ShutdownRebootForm.BackColor            = "#ffffff"
        $ShutdownRebootForm.FormBorderStyle      = 'FixedDialog'

        $ShutdownRebootTitle                     = New-Object system.Windows.Forms.Label
        $ShutdownRebootTitle.text                = "Would you like to Shutdown or Restart?"
        $ShutdownRebootTitle.AutoSize            = $true
        $ShutdownRebootTitle.width               = 25
        $ShutdownRebootTitle.height              = 10
        $ShutdownRebootTitle.location            = New-Object System.Drawing.Point(20,20)
        $ShutdownRebootTitle.Font                = 'Microsoft Sans Serif,13'

        $ShutdownConfirmBtn						 = New-Object system.Windows.Forms.Button
        $ShutdownConfirmBtn.BackColor         	 = "#ffffff"
        $ShutdownConfirmBtn.text              	 = "Shutdown"
        $ShutdownConfirmBtn.width             	 = 90
        $ShutdownConfirmBtn.height            	 = 30
        $ShutdownConfirmBtn.location          	 = New-Object System.Drawing.Point(300,100)
        $ShutdownConfirmBtn.Font              	 = 'Microsoft Sans Serif,10'
        $ShutdownConfirmBtn.ForeColor         	 = "#000"

        $RebootBtn                               = New-Object system.Windows.Forms.Button
        $RebootBtn.BackColor                     = "#ffffff"
        $RebootBtn.text                          = "Restart"
        $RebootBtn.width                         = 90
        $RebootBtn.height                        = 30
        $RebootBtn.location                      = New-Object System.Drawing.Point(200,100)
        $RebootBtn.Font                          = 'Microsoft Sans Serif,10'
        $RebootBtn.ForeColor                     = "#000"

        $CancelShutdownBtn                       = New-Object system.Windows.Forms.Button
        $CancelShutdownBtn.BackColor             = "#ffffff"
        $CancelShutdownBtn.text                  = "Cancel"
        $CancelShutdownBtn.width                 = 90
        $CancelShutdownBtn.height                = 30
        $CancelShutdownBtn.location              = New-Object System.Drawing.Point(25,100)
        $CancelShutdownBtn.Font                  = 'Microsoft Sans Serif,10'
        $CancelShutdownBtn.ForeColor             = "#000"
        $CancelShutdownBtn.DialogResult          = [System.Windows.Forms.DialogResult]::Cancel

        
        $ShutdownRebootForm.controls.AddRange(@($ShutdownRebootTitle,$ShutdownConfirmBtn,$RebootBtn,$CancelShutdownBtn))

        $ShutdownConfirmBtn.Add_Click({ Stop-Computer -ComputerName localhost })
        $RebootBtn.Add_Click({ Restart-Computer -ComputerName localhost })

        [void]$ShutdownRebootForm.ShowDialog()

    }

#------------[Script]------------

    $UploadBtn.Add_Click({ UploadLogs })
    $ShutdownBtn.Add_Click({ ShutdownReboot })

#------------[Show form]------------

    # Display the form
    [void]$OSDLogUploadForm.ShowDialog()
