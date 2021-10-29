. .\Code\Helper-Functions.ps1
$User = (Connect-AzureAD).Account.Id
$AuthToken = Get-AuthToken -User $User
$PSDefaultParameterValues["*:AuthToken"]=$AuthToken

# $ImportPath = ".\PAW\JSON\DeviceConfiguration"
# write-host $([convert]::ToBase64String((Get-Content .\PAW\XML\AppLockerScript.xml -Encoding byte)))


# $JSON_Data = Get-Content ".\PAW\JSON\DeviceConfiguration\PAW-Win10-AppLocker-Custom-CSP_25-11-2020-17-42-11.json"


# $uri = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations"
# $result = Invoke-RestMethod -Uri $uri -Headers $authToken -Method get -ContentType "application/json"
# $result.value | ConvertTo-Json -Depth 5 | clip

# $authtoken = Get-AuthToken $user

# Add-IntuneScopeTag -Name 'Privileged-Identity' -Description 'a' -authtoken $authtoken
.\Paw\Import-PAW-DeviceConfiguration.ps1
.\paw\Import-PAW-DeviceCompliancePolicies.ps1


$graphApiVersion = "Beta"
$DCP_resource = "deviceManagement/groupPolicyConfigurations"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
$responseBody = Invoke-RestMethod -Uri $uri -Headers $AuthToken -ContentType "application/json"
$responseBody.value | ConvertTo-Json -Depth 10 | clip

$graphApiVersion = "Beta"		
$DCP_resource = "deviceManagement/groupPolicyConfigurations/a0601eff-e016-4bbd-84f8-699d1f99256f/definitionValues/cd5ec6f0-db00-412c-8dd1-f59d520b22d8"
	
$uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
$result = Invoke-RestMethod -Uri $uri -Headers $AuthToken  -ContentType "application/json"
$result | ConvertTo-Json -Depth 10 | clip

$graphApiVersion = "Beta"
$DMS_resource = "deviceManagement/deviceManagementScripts"
Write-Verbose "Resource: $DMS_resource"
$uri = "https://graph.microsoft.com/$graphApiVersion/$DMS_resource/88f6cd65-4426-41f3-b784-379322627d7f"
$result = Invoke-RestMethod -Uri $uri -Headers $authToken -ContentType "application/json"
$result | ConvertTo-Json | clip



$scriptdir = ".\Code"
$ConfigPath = "C:\repos\personal\securedworkstation\Settings\PAW"
. $ScriptDir/Import-DeviceConfiguration.ps1 -ImportPath "$ConfigPath\JSON\DeviceConfiguration"
. $ScriptDir/Import-DeviceCompliancePolicies.ps1 -ImportPath "$ConfigPath\JSON\DeviceCompliance"
. $ScriptDir/Import-DeviceConfigurationADMX.ps1 -ImportPath "$ConfigPath\JSON\DeviceConfigurationADMX" -AADGroup 'Secure Workstations'
. $ScriptDir/Import-DeviceConfigScript.ps1 -ImportPath "$ConfigPath\JSON\DeviceManagementScripts"  -AADGroup 'Secure Workstations'

$ImportPath = "$ConfigPath\JSON\DeviceCompliance"
$a = Get-ChildItem $ImportPath -filter *.json | select -Last 1
$JSON_Data = Get-Content $a.FullName | Where-Object { $_ -notmatch "scheduledActionConfigurations@odata.context" }

$JSON_Convert = $JSON_Data | ConvertFrom-Json | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, scheduledActionsForRule@odata.context
$JSON = $JSON_Output

$ComplianceAssignments[1].target.groupId

$ex = $error[0]
