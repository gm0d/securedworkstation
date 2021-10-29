<#
.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.
#>
param (
	#Change Conditional Access State, default is disabled
	#Options: enabled, disabled, enabledForReportingButNotEnforced
	[String]$AADGroup = "Privileged Workstations"    
)

#$AADGroup = "PAW-Global-Devices"
$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
$ImportPath = $ScriptDir + "\JSON\DeviceConfigurationADMX"

if (!(Test-Path $ImportPath)) {
	Write-Error "Import Path for JSON file doesn't exist..." -ForegroundColor Red
	Write-Error "Script can't continue..." -ForegroundColor Red
	Write-Error
	break		
}

$TargetGroupId = (Get-AADGroup | Where-Object { $_.displayName -eq $AADGroup }).id
if ($null -eq $TargetGroupId -or $TargetGroupId -eq "") {
	Write-Error "AAD Group - [$AADGroup] doesn't exist, please specify a valid AAD Group..." -ForegroundColor Red
	Write-Error
	exit
}

Get-ChildItem $ImportPath -filter *.json |  
ForEach-Object {	
	$Policy_Name = $PSItem.Name.Substring(0, $PSItem.Name.Length - 5)	
	$DuplicateDCP = Get-GroupPolicyConfigurations -Name $Policy_Name
	if ($DuplicateDCP -eq $null) {
		$GroupPolicyConfigurationID = Create-GroupPolicyConfigurations -DisplayName $Policy_Name
		$JSON_Data = Get-Content $PSItem.FullName
		$JSON_Convert = $JSON_Data | ConvertFrom-Json
		$JSON_Convert | ForEach-Object { 			
			$JSON_Output = ConvertTo-Json -Depth 5 $PSItem
			Write-Verbose $JSON_Output
			Create-GroupPolicyConfigurationsDefinitionValues -JSON $JSON_Output -GroupPolicyConfigurationID $GroupPolicyConfigurationID 
		}		
		Write-Verbose "Policy: $Policy_Name created"

		$DeviceConfigs = Get-GroupPolicyConfigurations -name $Policy_Name
		$DeviceConfigID = $DeviceConfigs.id	
		Add-GroupPolicyConfigurationPolicyAssignment -ConfigurationPolicyId $DeviceConfigID -TargetGroupId $TargetGroupId -Assignment "groupAssignmentTarget"
	}
	else {
		Write-Warning "Device Configuration ADMX Profile: $Policy_Name has already been created"
	}
}