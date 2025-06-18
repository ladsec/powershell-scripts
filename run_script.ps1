# Základní info
Write-Host "=== Remote Script Runner ===`n"

# Zadání vzdaleneho pc


# Admin udaje pro pripojeni
$username = Read-Host "Zadej admin jmeno"
$password = Read-Host "Zadej heslo" -AsSecureString
$cred = New-Object System.Management.Automation.PSCredential($username, $password)
$computerName = Read-Host "Zadej jméno nebo IP cílového poèítaèe"

# Cesta ke skriptu na pc
$scriptPath = Read-Host "Zadej cestu ke skriptu, ktery chce spustit)"

# Naèti obsah skriptu
if (!(Test-Path $scriptPath)) {
    Write-Host "`n[CHYBA] Soubor skriptu nenalezen: $scriptPath" -ForegroundColor Red
    Read-Host "`nStiskni Enter pro ukonèení"
    exit
}
$scriptContent = Get-Content -Path $scriptPath -Raw

# Pokus o spuštìní skriptu na vzdáleným PC
Write-Host "`n[INFO] Pripojuji se k $computerName a spoustim script..." -ForegroundColor Cyan

try {
    $result = Invoke-Command -ComputerName $computerName -Credential $cred -ScriptBlock {
        param($code)
        Invoke-Expression $code
    } -ArgumentList $scriptContent -ErrorAction Stop

    Write-Host "`n[OK] Skript byl uspesne spusten na $computerName." -ForegroundColor Green
    if ($result) {
        Write-Host "`n--- vystup skriptu ---"
        $result
    }
}
catch {
    Write-Host "`n[CHYBA] Nepodatilo se spustit skript na $computerName" -ForegroundColor Red
    Write-Host $_.Exception.Message
}

# Konec
Read-Host "`nHotovo. Stiskni Enter pro ukonceni"
