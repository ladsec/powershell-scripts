Stop-Service -Force ccmexec -ErrorAction SilentlyContinue
Stop-Service -Force winmgmt

[String[]]$aWMIBinaries=@("unsecapp.exe","wmiadap.exe","wmiapsrv.exe","wmiprvse.exe","scrcons.exe")
foreach ($sWMIPath in @(($ENV:SystemRoot+"\System32\wbem"),($ENV:SystemRoot+"\SysWOW64\wbem"))){
	if(Test-Path -Path $sWMIPath){
		push-Location $sWMIPath
		foreach($sBin in $aWMIBinaries){
			if(Test-Path -Path $sBin){
				$oCurrentBin=Get-Item -Path  $sBin
				& $oCurrentBin.FullName /RegServer
			}
			else{
				if($sWMIPath -eq $ENV:SystemRoot+"\System32\wbem"){
					Write-Warning "soubor $sBin nebyl nalezen!"
				}
			}
		}
		Pop-Location
	}
}

if([System.Environment]::OSVersion.Version.Major -eq 5) 
{
   foreach ($sWMIPath in @(($ENV:SystemRoot+"\System32\wbem"),($ENV:SystemRoot+"\SysWOW64\wbem"))){
   		if(Test-Path -Path $sWMIPath){
			push-Location $sWMIPath
			dir /b *.mof *.mfl | findstr /v /i uninstall > moflist.txt 
			$aWMIManagedObjects=get-content .\moflist.txt #Get-ChildItem * -Include @("*.mof","*.mfl")
			foreach($sWMIObject in $aWMIManagedObjects){
				$oWMIObject=Get-Item -Path  $sWMIObject
				& mofcomp $oWMIObject.FullName				
			}
			Pop-Location
		}
   }
   if([System.Environment]::OSVersion.Version.Minor -eq 1)
   {
   		& rundll32 wbemupgd,UpgradeRepository
   }
   else{
   		& rundll32 wbemupgd,RepairWMISetup
   }
}
else{
	#Reset Repository
	& ($ENV:SystemRoot+"\system32\wbem\winmgmt.exe") /resetrepository
	& ($ENV:SystemRoot+"\system32\wbem\winmgmt.exe") /salvagerepository
}



push-Location C:\Windows\ccm
			$aWMIManagedObjects=Get-ChildItem * -Include @("*.mof","*.mfl")
			foreach($sWMIObject in $aWMIManagedObjects){
				$oWMIObject=Get-Item -Path  $sWMIObject
				& mofcomp $oWMIObject.FullName				
			}
			Pop-Location

Start-Service winmgmt
Start-Service ccmexec -ErrorAction SilentlyContinue
