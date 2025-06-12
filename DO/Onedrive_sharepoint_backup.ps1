#zaloha nastaveni onedrive a sharepoint pro presun na jiny pocitac
#zalohuje se reg soubor ve slozce uzivatele a ten staci otevrit/importovat na novy pc
#je treba odhlasit uzivatele, aby jeho ucet nebyl vyuzivany
$adminUser = Read-Host "Zadej admin uzivatelske jmeno"
$adminPass = Read-Host "Zadej admin heslo" -AsSecureString
$remotePC = Read-Host "Zadej nazev nebo IP vzdalenyho PC"

# Vytvoreni PS credential objektu
$cred = New-Object System.Management.Automation.PSCredential ($adminUser, $adminPass)

# Spusteni skriptu na vzdalenem PC
Invoke-Command -ComputerName $remotePC -Credential $cred -ScriptBlock {

    # ukonceni procesu
    Write-Host "ukoncovani procesu onedrive"
    $oneDriveProcess = Get-Process -Name OneDrive -ErrorAction SilentlyContinue
    if ($oneDriveProcess) {
        Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue
    }

    # ziskani uziv uctu ez slozky c:\users
    Write-Host "ziskani uzivatelskych uctu z c:\users"
    $users = Get-ChildItem -Path "C:\Users" -Directory

    # zaloha registru pro onedrive vsech uziv
    foreach ($user in $users) {
        $userHive = "C:\Users\$($user.Name)\NTUSER.DAT" # inicializace $userHive
        try {
            reg load HKU\TempHive "$userHive"
            Write-Host "Registr $userHive byl úspěšně načten."
            reg export HKU\TempHive\Software\Microsoft\OneDrive "C:\Users\$($user.Name)\OneDrive_Backup.reg" /y
            Write-Host "Registr OneDrive byl úspěšně exportován pro uživatele $($user.Name)."
            reg unload HKU\TempHive
            Write-Host "Registr HKU\TempHive byl úspěšně uvolněn."
        } catch {
            Write-Error "Chyba při zálohování registru pro uživatele $($user.Name): $_"
        }
    }

    Write-Host "OneDrive byl zalohovan"
}
