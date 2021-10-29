function Get-AuthToken {		
    <#
    .SYNOPSIS
    This function is used to authenticate with the Graph API REST interface
    .DESCRIPTION
    The function authenticate with the Graph API Interface with the tenant name
    .EXAMPLE
    Get-AuthToken
    Authenticates you with the Graph API interface
    .NOTES
    NAME: Get-AuthToken
    #>    
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        $User
    )

    $userUpn = New-Object "System.Net.Mail.MailAddress" -ArgumentList $User
    $tenant = $userUpn.Host
			
    # Getting path to ActiveDirectory Assemblies
    # If the module count is greater than 1 find the latest version
    $AADModule = Get-Module AzureAD -ListAvailable | Sort-Object version -Descending | Select-Object -First 1
    
    $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
    $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"			    

    [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null		
    [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null		
    
    $clientId = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547"
    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"
    $resourceAppIdURI = "https://graph.microsoft.com"
    $authority = "https://login.microsoftonline.com/$Tenant"		
    
    try {			
        
        $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
        # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
        # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession
        $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"
        $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($User, "OptionalDisplayableId")
        $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI, $clientId, $redirectUri, $platformParameters, $userId).Result
        
        # If the accesstoken is valid then create the authentication header			
        if ($authResult.AccessToken) {				
            # Creating header for Authorization token				
            $authHeader = @{
                'Content-Type'  = 'application/json'
                'Authorization' = "Bearer " + $authResult.AccessToken
                'ExpiresOn'     = $authResult.ExpiresOn
            }            
            return $authHeader				
        }			
        else {            
            throw "Authorization Access Token is null, please re-run authentication..."
        }			
    }		
    catch {			
        Write-Error $_.Exception.Message
        Write-Error $_.Exception.ItemName         			
    }		
}
Function Add-IntuneScopeTag {
    <#
    .SYNOPSIS
    This function is used to create a scope tag in intune using the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and creates a scope tag
    .EXAMPLE
    Add-IntuneScopeTag -Name PrivIdentity-tag
    Creates a scope tag
    .NOTES
    NAME: Add-IntuneScopeTag
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Description,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [hashtable]$AuthToken
    )

    $graphApiVersion = "Beta"
    $DCP_resource = "/deviceManagement/roleScopeTags"
    Write-Verbose "Resource: $DCP_resource"

    try {        
        $Body = @{
            "@odata.type" = "#microsoft.graph.roleScopeTag"
            displayName   = $Name
            description   = $Descrption
            isBuiltIn     = $false
        } | ConvertTo-Json
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
        $Result = Invoke-RestMethod -Uri $uri -Headers $AuthToken -Method Post -Body $Body -ContentType "application/json"
        return $Result
    }    
    catch {
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        Write-Host
        break
    }
}

Function Get-IntuneScopeTag {
    <#
    .SYNOPSIS
    This function is used to retrieve a specific scope tag, or all of them if no name is provided
    .DESCRIPTION
    The function connects to the Graph API Interface and list a scope tag/s
    .EXAMPLE
    Get-IntuneScopeTag -Name PrivIdentity-tag
    Gets a scope tag
    .NOTES
    NAME: Get-IntuneScopeTag
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [hashtable]$AuthToken
    )

    $graphApiVersion = "Beta"
    $DCP_resource = "deviceManagement/roleScopeTags"
    Write-Verbose "Resource: $DCP_resource"

    try {        
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
        $Result = Invoke-RestMethod -Uri $uri -Headers $AuthToken -Method Get -ContentType "application/json"
        if ($Name) {
            return ($Result.value | Where-Object displayName -eq $Name)
        }
        else {
            return $Result.Value
        }        
    }    
    catch {
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        Write-Host
        break
    }
}

Function Add-DeviceConfigurationPolicy {
    <#
    .SYNOPSIS
    This function is used to add an device configuration policy using the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and adds a device configuration policy
    .EXAMPLE
    Add-DeviceConfigurationPolicy -JSON $JSON
    Adds a device configuration policy in Intune
    .NOTES
    NAME: Add-DeviceConfigurationPolicy
    #>
    [cmdletbinding()]
    param(
        $JSON,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [hashtable]$AuthToken
    )

    $graphApiVersion = "Beta"
    $DCP_resource = "deviceManagement/deviceConfigurations"
    Write-Verbose "Resource: $DCP_resource"

    try {
        if ($JSON -eq "" -or $JSON -eq $null) {
            Write-Host "No JSON specified, please specify valid JSON for the Android Policy..." -f Red
        }
        else {
            Test-JSON -JSON $JSON
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
            Invoke-RestMethod -Uri $uri -Headers $AuthToken -Method Post -Body $JSON -ContentType "application/json"
        }
    }    
    catch {
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        Write-Host
        break
    }
}

Function Add-DeviceConfigurationPolicyAssignment {
    <#
    .SYNOPSIS
    This function is used to add a device configuration policy assignment using the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and adds a device configuration policy assignment
    .EXAMPLE
    Add-DeviceConfigurationPolicyAssignment -ConfigurationPolicyId $ConfigurationPolicyId -TargetGroupId $TargetGroupId
    Adds a device configuration policy assignment in Intune
    .NOTES
    NAME: Add-DeviceConfigurationPolicyAssignment
    #>
    [cmdletbinding()]
    param(
        $ConfigurationPolicyId,        
        $Assignments, # todo add valdation hashtable

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [hashtable]$AuthToken
    )
    $graphApiVersion = "Beta"
    $Resource = "deviceManagement/deviceConfigurations/$ConfigurationPolicyId/assignments"
    
    try {                             
        $JSON = @{
            Assignments = @($Assignments)
        } | ConvertTo-Json -depth 5    
       
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-RestMethod -Uri $uri -Headers $AuthToken -Method Post -Body $JSON -ContentType "application/json"
    }
    
    catch {
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        Write-Host
        break
    }
}

Function Get-DeviceConfigurationPolicy {
    <#
    .SYNOPSIS
    This function is used to get device configuration policies from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any device configuration policies
    .EXAMPLE
    Get-DeviceConfigurationPolicy
    Returns any device configuration policies configured in Intune
    .NOTES
    NAME: Get-DeviceConfigurationPolicy
    #>
    [cmdletbinding()]
    param(
        $name,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [hashtable]$AuthToken
    )
    $graphApiVersion = "Beta"
    $DCP_resource = "deviceManagement/deviceConfigurations"
    try {
        if ($Name) {
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
        (Invoke-RestMethod -Uri $uri -Headers $AuthToken -Method Get).Value | Where-Object { ($_.'displayName').contains("$Name") }
        }
        else {
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
        (Invoke-RestMethod -Uri $uri -Headers $AuthToken -Method Get).Value
        }
    }
    catch {
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        Write-Host
        break
    }
}

Function Get-AADGroup {
    <#
    .SYNOPSIS
    This function is used to get AAD Groups from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any Groups registered with AAD
    .EXAMPLE
    Get-AADGroup
    Returns all users registered with Azure AD
    .NOTES
    NAME: Get-AADGroup
    #>
    [cmdletbinding()]
    param(
        $GroupName,
        $id,
        [switch]$Members,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [hashtable]$AuthToken
    )
    # Defining Variables
    $graphApiVersion = "v1.0"
    $Group_resource = "groups"
    # pseudo-group identifiers for all users and all devices
    [string]$AllUsers = "acacacac-9df4-4c7d-9d50-4ef0226f57a9"
    [string]$AllDevices = "adadadad-808e-44e2-905a-0b7873a8a531"
    try {
        if ($id) {
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)?`$filter=id eq '$id'"
            switch ( $id ) {
                $AllUsers {
                    $grp = [PSCustomObject]@{ displayName = "All users" }; $grp           
                }
                $AllDevices {
                    $grp = [PSCustomObject]@{ displayName = "All devices" }; $grp         
                }
                default {
                    (Invoke-RestMethod -Uri $uri -Headers $AuthToken -Method Get).Value  
                }
            }                
        }
        elseif ($GroupName -eq "" -or $GroupName -eq $null) {
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)"
            (Invoke-RestMethod -Uri $uri -Headers $AuthToken -Method Get).Value
        }
        else {
            if (!$Members) {
                $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)?`$filter=displayname eq '$GroupName'"
                (Invoke-RestMethod -Uri $uri -Headers $AuthToken -Method Get).Value
            }
            elseif ($Members) {
                $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)?`$filter=displayname eq '$GroupName'"
                $Group = (Invoke-RestMethod -Uri $uri -Headers $AuthToken -Method Get).Value
                if ($Group) {
                    $GID = $Group.id
                    $Group.displayName
                    Write-Host
                    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)/$GID/Members"
                    (Invoke-RestMethod -Uri $uri -Headers $AuthToken -Method Get).Value
                }
            }
        }
    }
    catch {
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        Write-Host
        break
    }
}

Function Test-JSON {
    <#
    .SYNOPSIS
    This function is used to test if the JSON passed to a REST Post request is valid
    .DESCRIPTION
    The function tests if the JSON passed to the REST Post is valid
    .EXAMPLE
    Test-JSON -JSON $JSON
    Test if the JSON is valid before calling the Graph REST interface
    .NOTES
    NAME: Test-AuthHeader
    #>
    param (
        $JSON
    )
    try {
        $TestJSON = ConvertFrom-Json $JSON -ErrorAction Stop
        $validJson = $true
    }
    catch {
        $validJson = $false
        $_.Exception
    }
    if (!$validJson) {    
        Write-Host "Provided JSON isn't in valid JSON format" -f Red
        break
    }
}

Function Add-DeviceCompliancePolicy {
    <#
    .SYNOPSIS
    This function is used to add a device compliance policy using the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and adds a device compliance policy
    .EXAMPLE
    Add-DeviceCompliancePolicy -JSON $JSON
    Adds an iOS device compliance policy in Intune
    .NOTES
    NAME: Add-DeviceCompliancePolicy
    #>    
    [cmdletbinding()]    
    param(
        $JSON,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [hashtable]$AuthToken
    )
    
    $graphApiVersion = "Beta"
    $Resource = "deviceManagement/deviceCompliancePolicies"
        
    try {    
        if ($JSON -eq "" -or $JSON -eq $null) {    
            Write-Host "No JSON specified, please specify valid JSON for the iOS Policy..." -f Red    
        }    
        else {    
            Test-JSON -JSON $JSON    
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            Invoke-RestMethod -Uri $uri -Headers $AuthToken -Method Post -Body $JSON -ContentType "application/json"
        }
    }
    catch {
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        Write-Host
        break
    }
}

Function Get-DeviceCompliancePolicy {
    <#
    .SYNOPSIS
    This function is used to get device compliance policies from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any device compliance policies
    .EXAMPLE
    Get-DeviceCompliancePolicy
    Returns any device compliance policies configured in Intune
    .EXAMPLE
    Get-DeviceCompliancePolicy -Name
    Returns any device compliance policies with specific display name

    .NOTES
    NAME: Get-DeviceCompliancePolicy
    #>    
    [cmdletbinding()]    
    param(
        $Name,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [hashtable]$AuthToken
    )
    $graphApiVersion = "Beta"
    $Resource = "deviceManagement/deviceCompliancePolicies"
        
    try {    
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            (Invoke-RestMethod -Uri $uri -Headers $AuthToken -Method Get).Value | Where-Object { ($_.'@odata.type').contains("windows10CompliancePolicy") -and ($_.'displayName').contains($Name) }    
    }        
    catch {    
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        Write-Host
        break    
    }    
}

Function Add-DeviceCompliancePolicyAssignment {
    <#
    .SYNOPSIS
    This function is used to add a device compliance policy assignment using the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and adds a device compliance policy assignment
    .EXAMPLE
    Add-DeviceCompliancePolicyAssignment -ComplianceAssignments $ComplianceAssignments -CompliancePolicyId $CompliancePolicyId
    Adds a device compliance policy assignment in Intune
    .NOTES
    NAME: Add-DeviceCompliancePolicyAssignment
    #>
    
    [cmdletbinding()]    
    param(
        $CompliancePolicyId,
        $Assignments,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [hashtable]$AuthToken
    )
    
    $graphApiVersion = "v1.0"
    $Resource = "deviceManagement/deviceCompliancePolicies/$CompliancePolicyId/assign"
        
    try {
        $JSON = @{
            Assignments = @($ComplianceAssignments)
        } | ConvertTo-Json -depth 5
        Write-Output $JSON
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-RestMethod -Uri $uri -Headers $AuthToken -Method Post -Body $JSON -ContentType "application/json"    
    }
        
    catch {    
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        Write-Host
        break
    }    
}

Function Create-GroupPolicyConfigurations {		
    <#
    .SYNOPSIS
    This function is used to add an device configuration policy using the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and adds a device configuration policy
    .EXAMPLE
    Add-DeviceConfigurationPolicy -JSON $JSON
    Adds a device configuration policy in Intune
    .NOTES
    NAME: Add-DeviceConfigurationPolicy
    #>		
    [cmdletbinding()]
    param(
        $DisplayName,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [hashtable]$AuthToken
    )		
    $jsonCode = @{
        description = $null
        displayName = $DisplayName
    } | ConvertTo-Json
    
    $graphApiVersion = "Beta"
    $DCP_resource = "deviceManagement/groupPolicyConfigurations"
    Write-Verbose "Resource: $DCP_resource"		
    try {			
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
        $responseBody = Invoke-RestMethod -Uri $uri -Headers $AuthToken -Method Post -Body $jsonCode -ContentType "application/json"
    }		
    catch {			
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        Write-Host
        break			
    }
    $responseBody.id
}	
	
Function Create-GroupPolicyConfigurationsDefinitionValues {	
    <#
    .SYNOPSIS
    This function is used to get device configuration policies from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any device configuration policies
    .EXAMPLE
    Get-DeviceConfigurationPolicy
    Returns any device configuration policies configured in Intune
    .NOTES
    NAME: Get-GroupPolicyConfigurations
    #>
		
    [cmdletbinding()]
    Param (			
        [string]$GroupPolicyConfigurationID,
        $JSON,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [hashtable]$AuthToken			
    )		
    $graphApiVersion = "Beta"		
    $DCP_resource = "deviceManagement/groupPolicyConfigurations/$($GroupPolicyConfigurationID)/definitionValues"
    Write-Verbose $DCP_resource
    try {
        if ($JSON -eq "" -or $JSON -eq $null) {				
            Write-Error "No JSON specified, please specify valid JSON for the Device Configuration Policy..."
        }			
        else {				
            Test-JSON -JSON $JSON				
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
            Invoke-RestMethod -Uri $uri -Headers $AuthToken -Method Post -Body $JSON -ContentType "application/json"
        }			
    }		
    catch {			
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Error "Response content:`n$responseBody"
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        Write-Error
        break			
    }		
}

Function Get-GroupPolicyConfigurations {
    <#
    .SYNOPSIS
    This function is used to get device configuration policies from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any device configuration policies
    .EXAMPLE
    Get-DeviceConfigurationPolicy
    Returns any device configuration policies configured in Intune
    .NOTES
    NAME: Get-GroupPolicyConfigurations
    #>	
    [cmdletbinding()]
    param(
        $name,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [hashtable]$AuthToken
    )	
    $graphApiVersion = "Beta"
    $DCP_resource = "deviceManagement/groupPolicyConfigurations"
	
    try {		
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
		(Invoke-RestMethod -Uri $uri -Headers $AuthToken -Method Get).Value | Where-Object { $_.displayName -eq $Name }		
    }	
    catch {		
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        Write-Host
        break		
    }	
}

Function Add-GroupPolicyConfigurationPolicyAssignment {
    <#
    .SYNOPSIS
    This function is used to add a device configuration policy assignment using the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and adds a device configuration policy assignment
    .EXAMPLE
    Add-DeviceConfigurationPolicyAssignment -ConfigurationPolicyId $ConfigurationPolicyId -TargetGroupId $TargetGroupId
    Adds a device configuration policy assignment in Intune
    .NOTES
    NAME: Add-DeviceConfigurationPolicyAssignment
    #>
    [cmdletbinding()]
    param(
        $ConfigurationPolicyId,
        $TargetGroupId,
        $Assignment,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [hashtable]$AuthToken
    )

    $graphApiVersion = "Beta"
    $Resource = "deviceManagement/groupPolicyConfigurations/$ConfigurationPolicyId/assignments"
    
    try {
        if (!$ConfigurationPolicyId) {
            Write-Host "No Configuration Policy Id specified, specify a valid Configuration Policy Id" -f Red
            break
        }
        if (!$TargetGroupId) {
            Write-Host "No Target Group Id specified, specify a valid Target Group Id" -f Red
            break        
        }
        if (!$Assignment) {
            Write-Host "No Assignment Type specified, specify a valid Assignment Type" -f Red
            break
        }
        $JSON = @{
            target = @{
                "@odata.type" = "#microsoft.graph.$Assignment"
                groupId       = $TargetGroupId
            }
        } | ConvertTo-Json        

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-RestMethod -Uri $uri -Headers $AuthToken -Method Post -Body $JSON -ContentType "application/json"
    }    
    catch {
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        Write-Host
        break
    }
}

Function Add-DeviceManagementScript {
    <#
    .SYNOPSIS
    This function is used to add a device management script using the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and adds a device management script
    .EXAMPLE
    Add-DeviceManagementScript -File "path to powershell-script file"
    Adds a device management script from a File in Intune
    Add-DeviceManagementScript -File "URL to powershell-script file" -URL
    Adds a device management script from a URL in Intune
    .NOTES
    NAME: Add-DeviceManagementScript
    #>
    [cmdletbinding()]
    Param (
        # Path or URL to Powershell-script to add to Intune
        [Parameter(Mandatory = $true)]
        [string]$File,
        # PowerShell description in Intune
        [Parameter(Mandatory = $false)]
        [string]$Description,
        # Set to true if it is a URL
        [Parameter(Mandatory = $false)]
        [switch][bool]$URL = $false
    )
    if ($URL -eq $true) {
        $FileName = $File -split "/"
        $FileName = $FileName[-1]
        $OutFile = "$env:TEMP\$FileName"
        try {
            Invoke-WebRequest -Uri $File -UseBasicParsing -OutFile $OutFile
        }
        catch {
            Write-Error "Could not download file from URL: $File"
            break
        }
        $File = $OutFile
        if (!(Test-Path $File)) {
            Write-Error "$File could not be located."
            break
        }
    }
    elseif ($URL -eq $false) {
        if (!(Test-Path $File)) {
            Write-Error "$File could not be located."
            break
        }
        $FileName = Get-Item $File | Select-Object -ExpandProperty Name
    }
    $B64File = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($File));

    if ($URL -eq $true) {
        Remove-Item $File -Force
    }

    $JSON = [ordered]@{
        "@odata.type" = "#microsoft.graph.deviceManagementScript"
        displayName = $FileName
        description = $Description
        runSchedule = @{
            "@odata.type" = "microsoft.graph.runSchedule"
            }
        scriptContent = $B64File
        runAsAccount = "system"
        enforceSignatureCheck = "false"
        fileName = $FileName
        runAs32Bit = "true"
    } | ConvertTo-Json   

    $graphApiVersion = "Beta"
    $DMS_resource = "deviceManagement/deviceManagementScripts"
    Write-Verbose "Resource: $DMS_resource"

    try {
        $uri = "https://graph.microsoft.com/$graphApiVersion/$DMS_resource"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"
    }

    catch {
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Error "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"        
        break
    }
}

Function Add-DeviceManagementScriptAssignment {
    <#
    .SYNOPSIS
    This function is used to add a device configuration policy assignment using the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and adds a device configuration policy assignment
    .EXAMPLE
    Add-DeviceConfigurationPolicyAssignment -ConfigurationPolicyId $ConfigurationPolicyId -TargetGroupId $TargetGroupId
    Adds a device configuration policy assignment in Intune
    .NOTES
    NAME: Add-DeviceConfigurationPolicyAssignment
    #>

    [cmdletbinding()]
    param(
        $ScriptId,
        $TargetGroupId
    )

    $graphApiVersion = "Beta"
    $Resource = "deviceManagement/deviceManagementScripts/$ScriptId/assign"

    try {
        if (!$ScriptId) {
            Write-Error "No Script Policy Id specified, specify a valid Script Policy Id"
            break
        }

        if (!$TargetGroupId) {
            Write-Error "No Target Group Id specified, specify a valid Target Group Id"
            break
        }

        $JSON = [ordered]@{
            deviceManagementScriptGroupAssignments =   @(
                @{
                    "@odata.type" = "#microsoft.graph.deviceManagementScriptGroupAssignment"
                    targetGroupId = $TargetGroupId
                    id = $ScriptId
                }
            )
        } | ConvertTo-Json

        $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"
    }
    catch {
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Error "Response content:`n$responseBody"
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"        
        break
    }
}