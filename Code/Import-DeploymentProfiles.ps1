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
            Write-Host "`tAdding Autopilot profile [$($JSON_Convert.Settings.displayName)]" -ForegroundColor Green
            $Properties = Convert-ObjectToHashTable $JSON_Convert.Settings 
            $autopilotProfile = New-AutopilotProfile @Properties 

            Write-Verbose "Profile created with ID [$($autopilotProfile.Id)]"

            Write-Verbose "Creating assignments for profile"
            $JSON_Convert.assignments | 
                ForEach-Object {
                    $TargetGroupId = (Get-MgGroup -Filter "displayName eq '$PSItem'").id
                    if ($TargetGroupID){
                        Set-AutopilotProfileAssignedGroup -id $autopilotProfile.id -groupid $TargetGroupId | Out-Null
                }
            }
        }        
        else {
            Write-Warning "Autopilot profile: $($JSON_Convert.settings.displayName) has already been created"
        }
    }