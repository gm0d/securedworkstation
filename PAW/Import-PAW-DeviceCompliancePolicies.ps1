<#
.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.
#>

$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
$ImportPath = $ScriptDir + "\JSON\DeviceCompliance"

if (!(Test-Path $ImportPath)) {
    Write-Error "Import Path for JSON file doesn't exist..."
    Write-Error "Script can't continue..."
    Write-Error
    break
}

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
        Write-Host "Adding Device Configuration Policy [$DisplayName]" -ForegroundColor Yellow
        Add-DeviceCompliancePolicy -JSON $JSON_Output

        $DCPProfile = Get-DeviceCompliancePolicy -name $DisplayName
        $CompliancePolicyId = $DCPProfile.id            
        Write-Host "Device Configuration Policy ID '$CompliancePolicyId'" -ForegroundColor Yellow
        Write-Host

        #region Replace group assignments with actual values
        $ComplianceAssignments = @($JSON_Convert.assignments | 
            ForEach-Object {
                Write-Verbose "AAD Group Name: $($PSItem.target.groupId )"
                Write-Verbose "Assignment Type: $($PSItem.target."@OData.type")"

                $TargetGroupId = (Get-AADGroup -GroupName $PSItem.target.groupId).id    
                Write-Verbose "Included Group ID: $TargetGroupID"
                
                @{
                    target = @{
                        "@odata.type" = $PSItem.target."@OData.type" 
                        groupId       = $TargetGroupId
                    }
                }                
        })
        Add-DeviceCompliancePolicyAssignment -Assignments $ComplianceAssignments -CompliancePolicyId $CompliancePolicyId
        #endregion
        
    }
    else {
        Write-Warning "Device Compliance Policy: $($JSON_Convert.displayName) has already been created"
    }
}   
