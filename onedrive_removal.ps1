# Zeptani se na admin credentials a vzdaleny PC
$adminUser = Read-Host "Zadej admin uzivatelske jmeno"
$adminPass = Read-Host "Zadej admin heslo" -AsSecureString
$remotePC = Read-Host "Zadej nazev nebo IP vzdalenyho PC"

# Vytvoreni PS credential objektu
$cred = New-Object System.Management.Automation.PSCredential ($adminUser, $adminPass)

# Spusteni skriptu na vzdalenem PC
Invoke-Command -ComputerName $remotePC -Credential $cred -ScriptBlock {
    $logFile = "C:\Temp\OnedriveReset.log"
    
    Function Log {
        param ([string]$message)
        "$((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")) - $message" | Out-File -Append -FilePath $logFile
    }
    
    Log "--- Zacatek skriptu na reset OneDrive ---"
    
    # Ukonceni procesu OneDrive
    Log "Ukoncovani procesu OneDrive"
    $oneDriveProcess = Get-Process -Name OneDrive -ErrorAction SilentlyContinue
    if ($oneDriveProcess) {
        Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue
    }
    
    # Ziskani uzivatelskych slozek
    Log "Ziskani uzivatelskych slozek z C:\Users"
    $users = Get-ChildItem -Path "C:\Users" -Directory
    
    foreach ($user in $users) {
        $onedrivePath = "C:\Users\$($user.Name)\OneDrive - Strabag BRVZ GmbH"
        $sharepointPath = "C:\Users\$($user.Name)\Strabag BRVZ GmbH"
        
        if (Test-Path $onedrivePath) {
            Rename-Item -Path $onedrivePath -NewName "$onedrivePath.old" -Force
            Log "Prejmenovana slozka OneDrive pro uzivatele $($user.Name)"
        }
        if (Test-Path $sharepointPath) {
            Rename-Item -Path $sharepointPath -NewName "$sharepointPath.old" -Force
            Log "Prejmenovana slozka SharePoint pro uzivatele $($user.Name)"
        }
    }
    
    # Zaloha registru OneDrive
    Log "Zalohovani registru OneDrive"
    foreach ($user in $users) {
        $userHive = "C:\Users\$($user.Name)\NTUSER.DAT"
        if (Test-Path $userHive) {
            reg load HKU\TempHive "$userHive"
            reg export HKU\TempHive\Software\Microsoft\OneDrive "C:\Users\$($user.Name)\OneDrive_Backup.reg" /y
            reg unload HKU\TempHive
            Log "Zaloha registru pro uzivatele $($user.Name) hotova"
        }
    }
    
    # Odinstalace OneDrive
    Log "Odinstalace OneDrive"
    if (Test-Path "$env:SystemRoot\System32\OneDriveSetup.exe") {
        Start-Process "$env:SystemRoot\System32\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait
    } elseif (Test-Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe") {
        Start-Process "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait
    }
    
    # Smazani registru OneDrive s kontrolou
    Log "Mazani registru OneDrive"
    if (Test-Path "HKCU:\Software\Microsoft\OneDrive") {
        reg delete "HKCU\Software\Microsoft\OneDrive" /f
        Log "Smazany HKCU registr"
    }
    if (Test-Path "HKLM:\SOFTWARE\Microsoft\OneDrive") {
        reg delete "HKLM\SOFTWARE\Microsoft\OneDrive" /f
        Log "Smazany HKLM registr"
    }
    
    # Reinstalace OneDrive
    Log "Reinstalace OneDrive"
    Start-Process "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" -Wait
    
    # Overeni reinstalace
    Start-Sleep -Seconds 10
    if (Get-Process -Name OneDrive -ErrorAction SilentlyContinue) {
        Log "OneDrive uspesne reinstalovan a bezi."
    } else {
        Log "OneDrive se nezdarilo spustit po reinstalaci."
    }
    
    # Obnova registru OneDrive
    Log "Obnova registru OneDrive"
    foreach ($user in $users) {
        $userHive = "C:\Users\$($user.Name)\NTUSER.DAT"
        $backupFile = "C:\Users\$($user.Name)\OneDrive_Backup.reg"
        if (Test-Path $userHive -and Test-Path $backupFile) {
            reg load HKU\TempHive "$userHive"
            reg import "$backupFile"
            reg unload HKU\TempHive
            Log "Obnoveny registry pro uzivatele $($user.Name)"
        }
    }
    
    # Spusteni OneDrive
    Log "Spousteni OneDrive"
    Start-Process "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
    Log "OneDrive byl resetovan."
    
    Write-Host "Skript hotov, log soubor je zde: $logFile"
}
