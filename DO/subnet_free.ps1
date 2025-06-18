Install-Module -Name PSDiscoveryProtocol -Force


# Zadejte uživatelské jméno a heslo
$username = Read-Host "Zadejte uživatelské jméno"
$password = Read-Host "Zadejte heslo" -AsSecureString
$credential = New-Object System.Management.Automation.PSCredential($username, $password)

# Zadejte rozsah IP adres
$ipRange = Read-Host "Zadejte rozsah IP adres (např. 192.168.1.1-192.168.1.255)"

# Rozdělte rozsah na začátek a konec
$ipStart, $ipEnd = $ipRange -split '-'

# Převeďte IP adresy na číselné hodnoty
$ipStartNum = [System.Net.IPAddress]::Parse($ipStart).GetAddressBytes()
[Array]::Reverse($ipStartNum)
$ipStartNum = [System.BitConverter]::ToUInt32($ipStartNum, 0)

$ipEndNum = [System.Net.IPAddress]::Parse($ipEnd).GetAddressBytes()
[Array]::Reverse($ipEndNum)
$ipEndNum = [System.BitConverter]::ToUInt32($ipEndNum, 0)

# Projděte všechny IP adresy v rozsahu
for ($ipNum = $ipStartNum; $ipNum -le $ipEndNum; $ipNum++) {
    $ip = [System.Net.IPAddress]::Parse($ipNum).IPAddressToString

    # Zkontrolujte, zda je IP adresa online
    if (Test-Connection -ComputerName $ip -Count 1 -Quiet) {
        # Převeďte IP adresu na jméno počítače
        $computerName = [System.Net.Dns]::GetHostEntry($ip).HostName

        # Spusťte příkazy a uložte výsledek do souboru
            
            $prikaz = Invoke-Command -ComputerName $computerName -ScriptBlock { ipconfig } -Credential $credential

            # Výpis informací
            Write-Output "přikaz na $computerName a vystup je $prikaz" | Out-File -FilePath vysledky.txt -Append
         
        }
    }    