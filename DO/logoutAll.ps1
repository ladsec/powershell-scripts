#odhlaseni vsech uzivatelu
(quser) | ? { !$_.contains('USERNAME') } | % { logoff $_.substring(43,2).Trim() }; "Logoff"
