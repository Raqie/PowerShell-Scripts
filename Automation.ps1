#Script was made by Jakub Rak

$mail = Read-Host -Prompt 'Input mail: '
$user = Get-ADuser -Filter { EmailAddress -eq $mail }
$ext10 = Get-ADuser -Filter { EmailAddress -eq $mail } -Properties @("extensionattribute10")
$mobile = Get-ADuser -Filter { EmailAddress -eq $mail } -Properties Mobile | Select-Object Mobile
$sam = Get-ADuser -Filter { EmailAddress -eq $mail } -Properties sAMAccountName | Select -exp sAMAccountName
$country = get-aduser $sam -Properties co | select -exp co #user country
$diststring= get-aduser $sam -Properties distinguishedname | select distinguishedname | %{$_ -replace 'distinguishedname',''} | %{$_ -replace '@{=',''} | %{$_ -replace '}',''}

Get-ADuser -Filter { EmailAddress -eq $mail } -Properties @("extensionattribute9", "extensionattribute10", "extensionattribute14", "mobile")

Write-Host "--- if there's no ", "attribute9 /", " attribute10 /", "attribute 14 ", "or mobile ", "it means that it's not set ---" -ForegroundColor Red -BackgroundColor Black
#Pin hashing and adding to the account
#Here should be Switch case for Visible and Hidden number for hashing
$Hiddenorprivate = Read-Host -Prompt "1.Visible number 2.Hidden number"
switch ($Hiddenorprivate) {
    1 {
        Get-ADuser -Filter { EmailAddress -eq $mail } -Properties sAMAccountName, mobile | Select-Object sAMAccountName, mobile  | export-csv .\test.txt -NoTypeInformation -Delimiter ";" -Force -Encoding ASCII  
        gc .\test.txt | % { $_ -replace '"', "" } | % { $_ -replace '\s', '' } | out-file .\testP.txt -fo -en ascii

        .\PINHash.exe .\testP.txt

        $line = gc .\testP.txt -Delimiter ";" -Tail 2
    }
    2 {
        Get-ADuser -Filter { EmailAddress -eq $mail } -Properties sAMAccountName, extensionattribute10 | Select-Object sAMAccountName, extensionattribute10  | export-csv .\testPri.txt -NoTypeInformation -Delimiter ";" -Force -Encoding ASCII  
        gc .\testPri.txt | % { $_ -replace '"', "" } | out-file .\testPrivate.txt -fo -en ascii
        $content = gc .\testPrivate.txt | % { $_ -replace '\s', '' } 
        $namenumber = $content[1]
        set-content .\testPrivateFinal.txt -Value 'sAMAccountName;mobile', `n$namenumber

        .\PINHash.exe .\testPrivateFinal.txt

        $line = gc .\testPrivateFinal.txt -Delimiter ";" -Tail 2
    }
}

$hash = $line[1] | % { $_ -replace '\s', '' } 
$pin = $line[0]
$length = $hash.length

Set-ADUser -Identity $user -Replace @{extensionattribute9 = "$hash" } #ends here
Get-ADuser $user -Properties @("extensionattribute9", "extensionattribute10", "extensionattribute14", "mobile")

Write-Host "This is hash $hash" -BackgroundColor Green
Write-Host "This is pin $pin" -BackgroundColor Magenta
Write-Host "Hash length = $length" -BackgroundColor Cyan

#Adding Groups
if ($country -match "Colombia") {
    $country = "Spain"
}
else {}
if ($country -match "Czech Republic") {
    $country = "Czech"
}
else {}
if ($country -match "United Kingdom of Great Britain and Northern Ireland") {
    $country = "UK"
}
else {}
#If groups contains ICS or IGT
if($diststring -like '*ICS*'){
    $country = $country + "_ICS"
}
elseif($diststring -like '*IGT*'){
    $country = $country + "_IGT"
}
else{
    Write-Host "Program has not found ICS or IGT in OU of user $sam" -ForegroundColor Red
}

$whichgroups = Read-Host -Prompt "1.visiblevpn 2.hiddenvpn 3.visiblectx 4.hiddenctx" 

switch ($whichgroups) {
    1 {
        <#.\VisibleVPN.ps1#>
        $sgfastpass = "SG_Fastpass_MFA_Users_" + $country
        Add-ADGroupMember -Identity Callsign_vpn_USERS -Members $sam
        Add-ADGroupMember -Identity $sgfastpass -Members $sam
        Write-Host "user $sam added to $country VisibleVPN" -BackgroundColor Black -ForegroundColor Yellow
    }
    2 {
        <#.\HiddenVpn.ps1#>
        $sgfastpass = "SG_Fastpass_Users_" + $country

        Add-ADGroupMember -Identity Callsign_vpn_USERS2 -Members $sam
        Add-ADGroupMember -Identity $sgfastpass -Members $sam
        Write-Host "user $sam added to $country HiddenVPN" -BackgroundColor Black -ForegroundColor Yellow
    }
    3 {
        <#.\VisibleCTX.ps1#>
        $sgfastpass = "SG_Fastpass_MFA_Users_" + $country

        Add-ADGroupMember -Identity Callsign_ctx_USERS -Members $sam
        Add-ADGroupMember -Identity $sgfastpass -Members $sam
        Write-Host "user $sam added to $country VisibleCTX" -BackgroundColor Black -ForegroundColor Yellow
    }
    4 {
        <#.\HiddenCTX.ps1#>
        $sgfastpass = "SG_Fastpass_Users_" + $country

        Add-ADGroupMember -Identity Callsign_ctx_USERS2 -Members $sam
        Add-ADGroupMember -Identity $sgfastpass -Members $sam
        Write-Host "user $sam added to $country HiddenCTX" -BackgroundColor Black -ForegroundColor Yellow
    }
}
