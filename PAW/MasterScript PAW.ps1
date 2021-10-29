#Requires -Modules @{ModuleName="AzureAD"; ModuleVersion="2.0.2" }
<#
.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.
#>

# Determine script location for PowerShell
$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path

write-host "Loading helper functions"
. $ScriptDir/../Helper-Functions.ps1
    
####################################################        
    $AuthToken = Get-AuthToken
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
Create-IntuneScopeTag -Name 'Privileged-Identity' -Description 'Tag for privileged identities'

Write-Host "Adding Device Configuration Profiles"
. $ScriptDir/Import-PAW-DeviceConfiguration.ps1
Start-Sleep -s 5

Write-Host "Adding Device Compliance Policies"
. $ScriptDir/Import-PAW-DeviceCompliancePolicies.ps1
Start-Sleep -s 5

Write-Host "Adding ADMX Device settings"
. $ScriptDir/Import-PAW-DeviceConfigurationADMX.ps1 -AADGroup 'Secure Workstations'
Start-Sleep -s 5

Write-Host "Adding PS1 Config scripts"
. $ScriptDir/Import-DeviceConfigScript.ps1 -ImportPath $ScriptDir/Scripts  -AADGroup 'Secure Workstations'
Start-Sleep -s 5

#write-host "Adding Enrollment Status Page"
#. $ScriptDir/ESP_Import.ps1
#Start-Sleep -s 5

#write-host "Adding AutoPilot Profile"
#. $ScriptDir/AutoPilot_Import.ps1
#Start-Sleep -s 5

#write-host "Adding Device Enrollment Restrictions"
#. $ScriptDir/DER-Import_PAW.ps1
#Start-Sleep -s 5