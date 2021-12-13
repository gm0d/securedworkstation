#Requires -PSEdition Desktop
#Requires -Modules @{ModuleName="WindowsAutopilotIntune"; ModuleVersion="5.0"}, @{ModuleName="Microsoft.Graph.Authentication"; ModuleVersion="1.8.0" }, @{ModuleName="Microsoft.Graph.DeviceManagement"; ModuleVersion="1.8.0" }

[cmdletbinding()]
param(        
    [ValidateSet("SAW")] # At the moment the only supported configuration is SAW
    $Configuration = "SAW"
)

# Determine script location for PowerShell
$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
$ConfigPath = Resolve-Path $ScriptDir\..\Settings\$Configuration

Write-Host "Loading helper functions"
. $ScriptDir/Helper-Functions.ps1
Select-MgProfile -Name "beta"
    
####################################################        
Write-Host "Authenticating to MS Graph - Check authentication window" -ForegroundColor DarkGreen
Connect-MsGraph | Out-Null
$scopes = @('Group.ReadWrite.All'
    'Directory.ReadWrite.All'
    'Directory.AccessAsUser.All'
    'DeviceManagementConfiguration.ReadWrite.All'
    'DeviceManagementConfiguration.Read.All')
Connect-MgGraph -Scopes $scopes
####################################################    

# Get Auth token for Azure AD app id
Write-Host "AAD Groups"
# Connect-MgGraph -AccessToken $(Get-AuthToken -User $User -ClientId '1b730954-1685-4b74-9bfd-dac224a7b894') | Out-Null # client ID of AzureAD app 
. $ScriptDir/Import-AADObjects.ps1 -SettingsFile "$ConfigPath\JSON\AAD\Objects.json"
Write-Host "Waiting for AAD groups"
Start-Sleep -s 20

# Connect-MgGraph -AccessToken $(Get-AuthToken -User $User) | Out-Null
Write-Host "Device Compliance Policies"
. $ScriptDir/Import-CompliancePolicies.ps1 -ImportPath "$ConfigPath\JSON\CompliancePolicies"
Start-Sleep -s 5

Write-Host "Device Configuration Profiles"
. $ScriptDir/Import-ConfigurationProfiles.ps1 -ImportPath "$ConfigPath\JSON\ConfigurationProfiles"
Start-Sleep -s 5

# MsGraph stuff

write-host "Enrollment Status Page"
. $ScriptDir/Import-EnrollmentStatusPage.ps1 -ImportPath "$ConfigPath\JSON\EnrollmentStatusPage"
Start-Sleep -s 5

write-host "AutoPilot Profiles"
. $ScriptDir/Import-DeploymentProfiles.ps1 -ImportPath "$ConfigPath\JSON\DeploymentProfiles"
Start-Sleep -s 5

# Write-Host "Adding ADMX Device settings"
# . $ScriptDir/Import-ConfigurationProfilesADMX.ps1 -ImportPath "$ConfigPath\JSON\DeviceConfigurationADMX" -AADGroup 'SAW-Devices-UserDriven'
# Start-Sleep -s 5

# Write-Host "Adding PS1 Config scripts"
# . $ScriptDir/Import-DeviceConfigScript.ps1 -ImportPath "$ConfigPath\JSON\DeviceManagementScripts"
# Start-Sleep -s 5