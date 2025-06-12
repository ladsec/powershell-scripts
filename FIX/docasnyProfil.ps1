#smazani docasny profilu z pc
Function Fix-TemporaryProfile
{
    $PathProfiles = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
    $BAKKeys = Get-ChildItem Registry::$PathProfiles | Where-Object {$_.Name -clike '*.bak'}

    If($BAKKeys -eq $null)
    {
        Write-Warning "nejde na tomto pc."
    }Else
    {
        foreach($key in $BAKKeys)
        {
            $PathBAKKey = $key.Name
            $NameOriginalKey = ($key.PSChildName) -replace '.bak'
            $PathOriginalKey = $PathBAKKey -replace '.bak'
            $PathTempKey = $PathOriginalKey + ".temp"
            $NameTempKey = $NameOriginalKey + '.temp'
            
            $TempKeyExists = Test-Path -Path Registry::$PathTempKey
            $retry = 3
            Do
            {
                if($TempKeyExists -eq $true)
                {
                    Remove-Item -Path Registry::$PathTempKey -Force -Recurse -Confirm:$false
                    Start-Sleep -Seconds 1
                }
                $TempKeyExists = Test-Path -Path Registry::$PathTempKey
                $retry--
            }While(($TempKeyExists -eq $false) -and ($retry -gt 0))

            if($TempKeyExists -eq $false)
            {
                Rename-Item -Path Registry::$PathOriginalKey -NewName $NameTempKey -Force
                Rename-Item -Path Registry::$PathBAKKey -NewName $NameOriginalKey -Force
            }

            $BAKKeyExist = Test-Path -Path Registry::$PathBAKKey
            If($BAKKeyExist -eq $false)
            {
                Write-Host "hotovo. je treba restart pc" -ForegroundColor Green
            }
            Else
            {
                Write-Warning "tak nic. musí se smazat rucne"
            }
            Write-Host "[INFO] SID : $NameOriginalKey"
            Write-Host
        }
    }
}

Fix-TemporaryProfile
Remove-Item 'C:\Users\Temp*' -Force -recurse
