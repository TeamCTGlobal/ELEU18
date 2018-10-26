param($WebhookData)
<#
{
    "LengthInCm":  "30",
    "IPAddress":  "192.168.43.154",
    "Action":  "grab"
}
#>
$Body = $WebhookData.RequestBody | ConvertFrom-Json

$IPAddress = $Body.IPAddress
$Length = $Body.LengthInCm
$Action = $Body.Action

.\New-RobotFlow.ps1 -IPAddress $IPAddress -LengthInCm $Length -Action $actionb