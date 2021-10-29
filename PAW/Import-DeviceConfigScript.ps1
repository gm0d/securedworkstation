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

    [Parameter(Mandatory = $true)]
    [ValidateScript( {
        if (-Not (Get-AADGroup -GroupName $_) ) {
            throw "Group does not exist in AD"
        }    
        return $true
        })]
    [String]$AADGroup
)

$TargetGroupId = (Get-AADGroup -GroupName $AADGroup).id

Get-ChildItem $ImportPath -filter *.ps1 |
    Foreach-object {
        Write-Verbose "Adding Device Configuration Script from $($PSItem.FullName)"
        $Create_Local_Script = Add-DeviceManagementScript -File $($PSItem.FullName) -Description $($PSItem.BaseName)
        Write-Verbose "Device Management Script created as $($Create_Local_Script.id)"
        Write-Verbose "Assigning Device Management Script to AAD Group '$AADGroup'"

        $Assign_Local_Script = Add-DeviceManagementScriptAssignment -ScriptId $Create_Local_Script.id -TargetGroupId $TargetGroupId

        Write-Verbose "Assigned '$AADGroup' to $($Create_Local_Script.displayName)/$($Create_Local_Script.id)"        
    }