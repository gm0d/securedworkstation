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
        $DuplicateDCP = Get-DeviceCompliancePolicy -Name $JSON_Convert.displayName
        If ($DuplicateDCP -eq $null) {
            #region Replace scope tags with actual values
            $JSON_Convert.roleScopeTagIds = @($JSON_Convert.roleScopeTagIds | 
                ForEach-Object {
                    $st = Get-IntuneScopeTag -AuthToken $AuthToken -Name $PSItem
                    if ($st) {
                        # If scope tag was found, replace with the id
                        $st.id
                    }
                    else {
                        # Scope Tag not found, replace with Default
                        0
                    }
            })
            #endregion
                    
            $JSON_Output = $JSON_Convert | ConvertTo-Json -Depth 10                    
            Write-Verbose "Device Configuration Policy [$DisplayName] Found..."        
            Write-Host "Adding Device Configuration Policy [$DisplayName]" -ForegroundColor Green
            Add-DeviceCompliancePolicy -JSON $JSON_Output

            $DCPProfile = Get-DeviceCompliancePolicy -name $DisplayName
            $CompliancePolicyId = $DCPProfile.id            
            Write-Verbose "Device Configuration Policy ID '$CompliancePolicyId'"

            #region Replace group assignments with actual values
            $ComplianceAssignments = @($JSON_Convert.assignments | 
                ForEach-Object {
                    Write-Verbose "AAD Group Name: $($PSItem.target.groupId )"
                    Write-Verbose "Assignment Type: $($PSItem.target."@OData.type")"

                    $TargetGroupId = (Get-AADGroup -Filter "displayName eq '$($PSItem.target.groupId)'").id                        
                    if ($TargetGroupID){
                        Write-Verbose "Included Group ID: $TargetGroupID"
                        @{
                            target = @{
                                "@odata.type" = $PSItem.target."@OData.type" 
                                groupId       = $TargetGroupId
                            }
                        }   
                    }
                    else{
                        Write-Warning "Group [$($PSItem.target.groupId)] not found skipping assignment"
                    }
            })
            if($ComplianceAssignments){
                Add-DeviceCompliancePolicyAssignment -Assignments $ComplianceAssignments -CompliancePolicyId $CompliancePolicyId
            }
            else{
                Write-Warning 'No configuration assignments found'
            } 
            
            
            #endregion
            
        }
        else {
            Write-Warning "Device Compliance Policy: $($JSON_Convert.displayName) has already been created"
        }
    }   
