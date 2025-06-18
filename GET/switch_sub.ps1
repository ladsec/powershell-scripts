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
            # Získání informací o switchi pomocí PSDiscoveryProtocol
            #$switchInfo = $computerName | Invoke-DiscoveryProtocolCapture -Type LLDP -Force -Credential $credential | Get-DiscoveryProtocolData |  Invoke-DiscoveryProtocolCapture -Type CDP -Force -Credential $credential | Get-DiscoveryProtocolData               
            $switchInfo1 = $computerName | Invoke-DiscoveryProtocolCapture -Type CDP -Force -Credential $credential | Get-DiscoveryProtocolData            
            $switchInfo2 = $computerName | Invoke-DiscoveryProtocolCapture -Type LLDP -Force -Credential $credential | Get-DiscoveryProtocolData   


            # Získání aktuálně přihlášeného uživatele na vzdáleném počítači
            $loggedInUser = Invoke-Command -ComputerName $computerName -ScriptBlock { query user } -Credential $credential

            # Výpis informací
            Write-Output "IP: $ip, Jméno počítače: $computerName, Přihlášený uživatel: $loggedInUser, Switch1: $($switchInfo1.DeviceId), Switch1: $($switchInfo2.DeviceId)" | Out-File -FilePath vysledky.txt -Append
            
            # Výpis informací o switchi
            Write-Output "Informace o switchi:Informace o switchi1: $($switchInfo1 | Format-List | Out-String), Informace o switchi2: $($switchInfo2 | Format-List | Out-String)" | Out-File -FilePath vysledky.txt -Append
        }
    }    