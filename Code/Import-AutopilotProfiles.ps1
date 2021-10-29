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
        $JSON_Convert = Get-Content $_.FullName | ConvertFrom-Json
        
        $AutopilotProfile = Get-AutopilotProfile | Where-Object displayName -eq $JSON_Convert.settings.displayName
        
        If ($AutopilotProfile -eq $null) {
            #region Replace scope tags with actual values
            $JSON_Convert.roleScopeTagIds = @($JSON_Convert.roleScopeTagIds | ForEach-Object {
                $st = Get-IntuneScopeTag -Name $PSItem
                if($st){ # If scope tag was found, replace with the id
                    $st.id
                }
                else{ # Scope Tag not found, replace with Default
                    0
                }
            })
            #endregion
                        
            Write-Host "Adding Autopilot profile [$($JSON_Convert.Settings.displayName)]" -ForegroundColor Green
            $Properties = Convert-ObjectToHashTable $JSON_Convert.Settings 
            $Profile = New-AutopilotProfile @Properties 

            Write-Verbose "Profile created with ID [$($Profile.Id)]"

            Write-Verbose "Creating assignments for profile"
            $JSON_Convert.assignments | 
                ForEach-Object {
                    $TargetGroupId = (Get-AADGroup -Filter "displayName eq '$PSItem'").id
                    if ($TargetGroupID){
                        Set-AutopilotProfileAssignedGroup -id $Profile.id -groupid $TargetGroupId | Out-Null
                }
            }
        }        
        else {
            Write-Warning "Autopilot profile: $($JSON_Convert.settings.displayName) has already been created"
        }
    }