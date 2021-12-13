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
        
        $ESPage = Get-EnrollmentStatusPage | Where-Object displayName -eq $JSON_Convert.displayName
        
        If ($ESPage -eq $null) {                        
            Write-Host "`tAdding Enrollment status page [$($JSON_Convert.displayName)]" -ForegroundColor Green
            $Properties = @{
                DisplayName = $JSON_Convert.displayName
                Description =$JSON_Convert.description
                Message = $JSON_Convert.customErrorMessage
                HideProgress = $JSON_Convert.showInstallationProgress
                AllowUseOnFailure = $JSON_Convert.allowDeviceUseOnInstallFailure
                AllowResetOnError = $JSON_Convert.allowDeviceResetOnInstallFailure
                AllowCollectLogs = $JSON_Convert.allowLogCollectionOnInstallFailure                
                blockDeviceSetupRetryByUser = $JSON_Convert.blockDeviceSetupRetryByUser
                TimeoutInMinutes = $JSON_Convert.installProgressTimeoutInMinutes
            }
            $ESP = Add-EnrollmentStatusPage @Properties 
            Write-Verbose "ESP created with ID [$($ESP.Id)]"

            # cmdlet is hitting the incorrect endpoint and creates a wron structure, it can be done via api with
            # POST /v1.0/deviceManagement/deviceEnrollmentConfigurations/6af31291-8af3-496a-a685-1630124a8acd_Windows10EnrollmentCompletionPageConfiguration/assign HTTP/1.1
            # {
            #     "enrollmentConfigurationAssignments": [
            #         {
            # "target": {
            # "@odata.type": "#microsoft.graph.groupAssignmentTarget",
            #                 "groupId": "cf10c681-076f-40d6-9838-6f4dfaf0102f"
            #             }
            #         }
            #     ]
            # }
        
            # Write-Verbose "Creating assignments for ESP"
            # $JSON_Convert.assignments.target | 
            #     ForEach-Object {
            #         $TargetGroupId = (Get-MgGroup -Filter "displayName eq '$($PSItem.groupId)'").id                    
            #         if ($TargetGroupID){
            #             $PSItem.groupId = $TargetGroupId
            #             New-IntuneDeviceEnrollmentConfigurationAssignment -deviceEnrollmentConfigurationId $ESP.id -target $PSItem
            #             Write-Verbose "ESP Assignment [$($ESP.DisplayName)] [$($PSItem.groupId)]"
            #         }
            #         else{
            #             Write-Warning "Group [$($PSItem.groupId)] not found "
            #         }
            # }
        }        
        else {
            Write-Warning "ESP: $($JSON_Convert.displayName) has already been created"
        }
    }