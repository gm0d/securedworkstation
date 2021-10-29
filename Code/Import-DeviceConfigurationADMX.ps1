<#
.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.
#>
param (
	[Parameter(Mandatory = $true)]
    [ValidateScript( {
        if (-Not ($_ | Test-Path) ) {
            throw "Folder does not exist"
        }
        if (-Not ($_ | Test-Path -PathType Container) ) {
            throw "The Path argument must be a Folder."
        }
        return $true
        })]
    [System.IO.FileInfo]$ImportPath,

	[String]$AADGroup = "Privileged Workstations"    
)

$TargetGroupId = (Get-AADGroup | Where-Object { $_.displayName -eq $AADGroup }).id
if ($null -eq $TargetGroupId -or $TargetGroupId -eq "") {
	Write-Error "AAD Group - [$AADGroup] doesn't exist, please specify a valid AAD Group..."
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
		Write-Host "Policy: $Policy_Name created" -ForegroundColor Green

		$DeviceConfigs = Get-GroupPolicyConfigurations -name $Policy_Name
		$DeviceConfigID = $DeviceConfigs.id	
		Add-GroupPolicyConfigurationPolicyAssignment -ConfigurationPolicyId $DeviceConfigID -TargetGroupId $TargetGroupId -Assignment "groupAssignmentTarget"
	}
	else {
		Write-Warning "Device Configuration ADMX Profile: $Policy_Name has already been created"
	}
}