Install-Module -Name PSDiscoveryProtocol -Force


$PC = Read-Host -Prompt 'Input the PC name'
$PC | Invoke-DiscoveryProtocolCapture -Type CDP | Get-DiscoveryProtocolData
$PC | Invoke-DiscoveryProtocolCapture -Type LLDP | Get-DiscoveryProtocolData