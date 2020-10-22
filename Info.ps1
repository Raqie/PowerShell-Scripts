#Script was made by Jakub Rak

$mail = Read-Host -Prompt 'Input mail: '
$user = Get-ADuser -Filter { EmailAddress -eq $mail }

Get-ADuser -Filter { EmailAddress -eq $mail } -Properties @("extensionattribute9", "extensionattribute10", "extensionattribute14", "mobile") 
(GET-ADUSER –Identity $user –Properties MemberOf | Select-Object MemberOf).MemberOf

Write-Host "--- if there's no ", "attribute9 /", " attribute10 /", "attribute 14 ", "or mobile ", "it means that it's not set ---" -ForegroundColor Red -BackgroundColor Black