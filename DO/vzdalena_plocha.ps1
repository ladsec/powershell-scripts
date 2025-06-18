#[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
#[System.Text.Encoding]::UTF8.GetBytes("text s diakritikou")
#$OutputEncoding = [System.Text.Encoding]::UTF8

# Zadejte údaje pro připojení
$Computer = Read-Host "Zadej jméno nebo IP adresu vzdáleného počítače"
$username = Read-Host "Zadej uživatelské jméno"
$password = Read-Host "Zadej heslo" -AsSecureString

# Cesta k logovacímu souboru
#$logFile = "$env:TEMP\remote_script_log.txt"
#$logFile = "$env:c:\users\zouplnalad\desktop\remote_script_log.txt"

# Funkce pro zápis do logu C:\Users\username\AppData\Local\Temp
#function Write-Log {
 #   param (
  #      [string]$message
   # )
    #$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    #Add-Content -Path $logFile -Value "$timestamp - $message"
#}

# Vytvoření připojení k vzdálenému počítači
#Write-Log "Vytváření připojení k vzdálenému počítači $Computer."
$session = New-PSSession -ComputerName $Computer -Credential (New-Object System.Management.Automation.PSCredential($username, $password))



# Zastavení služeb Remote Desktop na vzdáleném počítači
#Write-Log "Zastavení služeb Remote Desktop na vzdáleném počítači."
Invoke-Command -Session $session -ScriptBlock {
    Net stop TermService /y

    #nastavi opravneni na soubor
    takeown /F c:\Windows\System32\termsrv.dll /A
    icacls c:\Windows\System32\termsrv.dll /grant Administrators:F
}



#Write-Log "Vytvoření zálohy souboru termsrv.dll."
Invoke-Command -Session $session -ScriptBlock {
    # Záloha termsrv.dll na termsrv.dll_bak
    Copy-Item -Path "C:\Windows\System32\termsrv.dll" -Destination "C:\Windows\System32\termsrv.dll_bak" -Force
    
    # Kontrola, zda již existuje termsrv.dll_ORIG
    if (Test-Path "C:\Windows\System32\termsrv.dll_ORIG") {
        $lastWriteTime = (Get-Item "C:\Windows\System32\termsrv.dll_ORIG").LastWriteTime
        if ($lastWriteTime -lt (Get-Date).AddDays(-7)) {
            # Přepsání souboru, pokud je starší než týden
            Copy-Item -Path "C:\Windows\System32\termsrv.dll" -Destination "C:\Windows\System32\termsrv.dll_ORIG" -Force
            Write-Output "Soubor termsrv.dll_ORIG byl přepsán, protože byl starší než týden."
        } else {
            Write-Output "Soubor termsrv.dll_ORIG není starší než týden, nebyl přepsán."
        }
    } else {
        # Pokud neexistuje, vytvoří se záloha termsrv.dll na termsrv.dll_ORIG
        Copy-Item -Path "C:\Windows\System32\termsrv.dll" -Destination "C:\Windows\System32\termsrv.dll_ORIG"
        Write-Output "Soubor termsrv.dll_ORIG neexistoval, byla vytvořena nová kopie."
    }
}





# Načtení souboru jako byte array a vyhledání a nahrazení bajtů
#Write-Log "Načtení souboru termsrv.dll a vyhledání a nahrazení bajtů."
Invoke-Command -Session $session -ScriptBlock {
    $dllBytes = [System.IO.File]::ReadAllBytes("C:\Windows\System32\termsrv.dll")

    $knownBytes = [byte[]] (0x39, 0x81, 0x3C, 0x06, 0x00, 0x00)
    $newBytes = [byte[]] (0xB8, 0x00, 0x01, 0x00, 0x00, 0x89, 0x81, 0x38, 0x06, 0x00, 0x00, 0x90)

    $replacementSuccess = $false
    for ($i = 0; $i -le $dllBytes.Length - $newBytes.Length; $i++) {
        $match = $true
        for ($j = 0; $j -lt $knownBytes.Length; $j++) {
            if ($dllBytes[$i + $j] -ne $knownBytes[$j]) {
                $match = $false
                break
            }
        }
        if ($match) {
            [System.Array]::Copy($newBytes, 0, $dllBytes, $i, $newBytes.Length)
            $replacementSuccess = $true
            break
        }
    }

    if (-not $replacementSuccess) {
         # Pokud se nahrazení nepodaří, přepsání souboru termsrv.dll souborem ORIG a znovu pokus
        Copy-Item -Path "C:\Windows\System32\termsrv.dll_ORIG" -Destination "C:\Windows\System32\termsrv.dll" -Force
        Write-Output "Nahrazení bajtů se nepodařilo, soubor termsrv.dll byl přepsán souborem ORIG."
        
        # Znovu pokus o nahrazení bajtů
        $dllBytes = [System.IO.File]::ReadAllBytes("C:\Windows\System32\termsrv.dll")
        $replacementSuccess = $false
        for ($i = 0; $i -le $dllBytes.Length - $newBytes.Length; $i++) {
            $match = $true
            for ($j = 0; $j -lt $knownBytes.Length; $j++) {
                if ($dllBytes[$i + $j] -ne $knownBytes[$j]) {
                    $match = $false
                    break
                }
            }
            if ($match) {
                [System.Array]::Copy($newBytes, 0, $dllBytes, $i, $newBytes.Length)
                $replacementSuccess = $true
                break
            }
        }

        if ($replacementSuccess) {
            [System.IO.File]::WriteAllBytes("C:\Windows\System32\termsrv.dll", $dllBytes)
            Write-Output "Nahrazení bajtů bylo úspěšné na druhý pokus."
        } else {
            Write-Output "Nahrazení bajtů se nepodařilo ani na druhý pokus."
            exit
        }
    } else {
        [System.IO.File]::WriteAllBytes("C:\Windows\System32\termsrv.dll", $dllBytes)
        Write-Output "Nahrazení bajtů bylo úspěšné."
    
    }

    [System.IO.File]::WriteAllBytes("C:\Windows\System32\termsrv.dll", $dllBytes)
}


# Restartování služeb Remote Desktop na vzdáleném počítači
#Write-Log "Restartování služeb Remote Desktop na vzdáleném počítači."
Invoke-Command -Session $session -ScriptBlock {
    Net start TermService /y
}

# Otevření připojení ke vzdálené ploše na vašem počítači
#Write-Log "Otevření připojení ke vzdálené ploše na vašem počítači."
#Start-Process "mstsc.exe" -ArgumentList "/v:$Computer /admin /f /u:$username /p:$($password | ConvertFrom-SecureString)"
#Start-Process "mstsc.exe" "/v:$Computer /admin /f /prompt)"

Start-Process "mstsc.exe" -ArgumentList "/v:$Computer /admin /f" 


# Čekání na uzavření vzdálené plochy
wait-process -Name mstsc
Write-Output "vzdalena plocha byla zavrena"


# Čekání na uzavření připojení ke vzdálené ploše
#Write-Log "Čekání na uzavření připojení ke vzdálené ploše."
#Write-Host "Stiskněte Enter po uzavření připojení ke vzdálené ploše..."
#Read-Host

# Obnovení původního souboru termsrv.dll
#Write-Log "Obnovení původního souboru termsrv.dll."


Invoke-Command -Session $session -ScriptBlock {
    Net stop TermService /y
    $processExists = (tasklist /m termsrv.dll) -match "termsrv.dll"
    
    if ($processExists) {
        $processName = (tasklist /m termsrv.dll | Select-String "termsrv.dll" | ForEach-Object { $_ -split '\s+' })[0]
        $taskkillResult = taskkill /IM $processName /F
        
        if ($taskkillResult -match "ERROR") {
            $qwinstaResult = qwinsta
            if ($qwinstaResult -match "rdp-tcp") {
                $rdpTcpId = ($qwinstaResult | Select-String "rdp-tcp" | ForEach-Object { $_ -split '\s+' })[2]
                Stop-Process -Force -Id $rdpTcpId
                Write-Output "Proces $rdpTcpId používající rdp-tcp byl úspěšně ukončen."
            } else {
                Write-Output "Služba rdp-tcp nebyla nalezena."
            }
        } else {
            Write-Output "Proces $processName používající termsrv.dll byl úspěšně ukončen."
        }
    } else {
        Write-Output "Žádný proces nepoužívá termsrv.dll."
    }

    try {
        Copy-Item -Path "C:\Windows\System32\termsrv.dll_bak" -Destination "C:\Windows\System32\termsrv.dll" -Force
        Remove-Item -Path "C:\Windows\System32\termsrv.dll_bak"
        Write-Output "Soubor termsrv.dll byl úspěšně nahrazen a původní záloha odstraněna."
    } catch {
        Write-Output "Došlo k chybě při nahrazování souboru termsrv.dll: $_"
    }

    try {
        Net start TermService /y
        Write-Output "Služba vzdálené plochy byla úspěšně spuštěna."
    } catch {
        Write-Output "Došlo k chybě při spouštění služby vzdálené plochy: $_"
    }
}


# Uzavření relace
#Write-Log "Uzavření relace."
Remove-PSSession -Session $session

#Write-Log "Skript byl úspěšně dokončen."
Write-Host "Skript byl úspěšně dokončen."
