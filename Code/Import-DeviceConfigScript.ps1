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
        $JSON_Data = Get-Content $_.FullName

        # Excluding entries that are not required - id,createdDateTime,lastModifiedDateTime,version
        $JSON_Convert = $JSON_Data | ConvertFrom-Json | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime        

        $DuplicateDMS = Get-DeviceManagementScript -Name $JSON_Convert.displayName
        
        If ($DuplicateDMS -eq $null) {
            #region Replace scope tags with actual values
            $JSON_Convert.roleScopeTagIds = @($JSON_Convert.roleScopeTagIds | ForEach-Object {
                $st = Get-IntuneScopeTag -AuthToken $AuthToken -Name $PSItem
                if($st){ # If scope tag was found, replace with the id
                    $st.id
                }
                else{ # Scope Tag not found, replace with Default
                    0
                }
            })
            #endregion

            $JSON_Output = $JSON_Convert | ConvertTo-Json -Depth 5              
            
            Write-Host "Adding Device Configuration Script from [$($JSON_Convert.fileName)]" -ForegroundColor Green
            $Create_Local_Script = Add-DeviceManagementScript -JSON $JSON_Output

            Write-Verbose "Assigning Device Management Script to AAD Group '$AADGroup'"
            $JSON_Convert.assignments | 
                ForEach-Object {
                    $TargetGroupId = (Get-AADGroup -Filter "displayName eq '$PSItem'").id
                    if ($TargetGroupID){
                        $Assign_Local_Script = Add-DeviceManagementScriptAssignment -ScriptId $Create_Local_Script.id -TargetGroupId $TargetGroupId
                        Write-Verbose "Assigned '$AADGroup' to $($Create_Local_Script.displayName)/$($Create_Local_Script.id)"
                }
            }
        }        
        else {
            Write-Warning "Device Management Script: $($JSON_Convert.displayName) has already been created"
        }
    }