#Requires -Modules @{ModuleName="AzureAD"; ModuleVersion="2.0.2" }, @{ModuleName="WindowsAutopilotIntune"; ModuleVersion="5.0" }
<#
.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.
#>
[cmdletbinding()]
param(        
    [ValidateSet("PAW","ENT","SPE")]
    $Configuration = "PAW"
)

# Determine script location for PowerShell
$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
$ConfigPath = Resolve-Path $ScriptDir\..\Settings\$Configuration

Write-Host "Loading helper functions"
. $ScriptDir/Helper-Functions.ps1
    
####################################################        
Write-Host "Authenticating to Azure AD - Check authentication window" -ForegroundColor DarkGreen
$User = (Connect-AzureAD).Account.Id    
$AuthToken = Get-AuthToken -User $User
$Global:PSDefaultParameterValues["*:AuthToken"] = $AuthToken 
####################################################    

#write-host "Adding App Registrtion"
#. $ScriptDir/AppRegistration_Create.ps1
#Start-Sleep -s 5

#write-host "Adding required AAD Groups"
# . $ScriptDir/AADGroups_Create.ps1

#write-host "Adding AAD Group Membership"
# . $ScriptDir/AADGroupMemberships_Add.ps1
# Start-Sleep -s 5

#write-host "Adding Named Locations"
#. $ScriptDir/NamedLocations_Import.ps1 -user $user
#Start-Sleep -s 5

#write-host "Adding Conditional Access Policies"
#. $ScriptDir/CA-Policies-Import_PAW.ps1 -State "Disabled"
#Start-Sleep -s 5

Write-Host "Creating Scope tag"
Add-IntuneScopeTag -Name 'Privileged-Identity' -Description 'Tag for privileged identities' | Out-Null

Write-Host "Adding Device Configuration Profiles"
. $ScriptDir/Import-DeviceConfiguration.ps1 -ImportPath "$ConfigPath\JSON\DeviceConfiguration"
Start-Sleep -s 5

Write-Host "Adding Device Compliance Policies"
. $ScriptDir/Import-DeviceCompliancePolicies.ps1 -ImportPath "$ConfigPath\JSON\DeviceCompliance"
Start-Sleep -s 5

Write-Host "Adding ADMX Device settings"
. $ScriptDir/Import-DeviceConfigurationADMX.ps1 -ImportPath "$ConfigPath\JSON\DeviceConfigurationADMX" -AADGroup 'Secure-Workstations'
Start-Sleep -s 5

Write-Host "Adding PS1 Config scripts"
. $ScriptDir/Import-DeviceConfigScript.ps1 -ImportPath "$ConfigPath\JSON\DeviceManagementScripts"
Start-Sleep -s 5

#write-host "Adding Enrollment Status Page"
#. $ScriptDir/ESP_Import.ps1
#Start-Sleep -s 5

write-host "Adding AutoPilot Profile"
. $ScriptDir/Import-AutopilotProfiles.ps1 -ImportPath "$ConfigPath\JSON\Autopilot"
Start-Sleep -s 5

#write-host "Adding Device Enrollment Restrictions"
#. $ScriptDir/DER-Import_PAW.ps1
#Start-Sleep -s 5