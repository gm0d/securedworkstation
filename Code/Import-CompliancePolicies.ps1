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
    [System.IO.FileInfo]$ImportPath    
)

Get-ChildItem $ImportPath -filter *.json |
Foreach-object {
    $JSON_Data = Get-Content $_.FullName | Where-Object { $_ -notmatch "scheduledActionConfigurations@odata.context" }
    # Excluding entries that are not required - id,createdDateTime,lastModifiedDateTime,version
    $JSON_Convert = $JSON_Data | ConvertFrom-Json | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, scheduledActionsForRule@odata.context
    $DisplayName = $JSON_Convert.displayName
    $DuplicateDCP = Get-MgDeviceManagementDeviceCompliancePolicy -filter "displayname eq '$($JSON_Convert.displayName)'"  
        
    If ($DuplicateDCP -eq $null) {                   
        $JSON_Output = $JSON_Convert | ConvertTo-Json -Depth 10            
        Write-Host "Adding Device Configuration Policy [$DisplayName]" -ForegroundColor Green
        $DeviceCompliancePolicy = New-MgDeviceManagementDeviceCompliancePolicy -BodyParameter $JSON_Output                        
        Write-Verbose "Device Configuration Policy ID [$($DeviceCompliancePolicy.Id)] created"

        #region Replace group assignments with actual values
        $JSON_Convert.assignments | 
            ForEach-Object {
                Write-Verbose "AAD Group Name: $($PSItem.target.groupId )"
                Write-Verbose "Assignment Type: $($PSItem.target."@OData.type")"

                $TargetGroupId = (Get-MgGroup -Filter "displayName eq '$($PSItem.target.groupId)'").id                         
                if ($TargetGroupID) {
                    Write-Verbose "Included Group ID: $TargetGroupID"
                    $Assignment = @{
                        target = @{
                            "@odata.type" = $PSItem.target."@OData.type" 
                            groupId       = $TargetGroupId
                        }
                    } | ConvertTo-Json -Depth 5
                    $DeviceCompliancePolicyAssignment = Set-MgDeviceManagementDeviceCompliancePolicy -DeviceCompliancePolicyId $DeviceCompliancePolicy.Id -Assignments $Assignment
                    Write-Verbose "Device compliance policy assignment [$($DeviceCompliancePolicyAssignment.id)] created"
                }
                else {
                    Write-Warning "Group [$($PSItem.target.groupId)] not found skipping assignment"
                }
            }        
        #endregion            
    }
    else {
        Write-Warning "Device Compliance Policy: $($JSON_Convert.displayName) has already been created"
    }
}   
