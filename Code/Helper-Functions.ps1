function Convert-ObjectToHashtable {
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    process {
        if ($null -eq $InputObject) {
            return $null 
        }

        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @(
                foreach ($object in $InputObject) {
                    Convert-ObjectToHashtable $object 
                }
            )

            Write-Output -NoEnumerate $collection
        }
        elseif ($InputObject -is [psobject]) {
            $hash = @{}

            foreach ($property in $InputObject.PSObject.Properties) {
                $hash[$property.Name] = Convert-ObjectToHashtable $property.Value
            }

            $hash
        }
        else {
            $InputObject
        }
    }
}
function Get-AuthToken {
    <#
    .SYNOPSIS
    This function is used to authenticate with the Graph API REST interface
    .DESCRIPTION
    The function authenticate with the Graph API Interface with the tenant name
    .EXAMPLE
    Get-AuthHeader
    Authenticates you with the Graph API interface
    .NOTES
    NAME: Get-AuthHeader
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        $User,

        [Parameter(Mandatory = $false)]
        [guid]$ClientId = 'd1ddf0e4-d672-4dae-b554-9d5bdfd93547'
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
            $authResult.AccessToken            
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

function Get-AuthHeader {
    <#
    .SYNOPSIS
    This function is used to authenticate with the Graph API REST interface
    .DESCRIPTION
    The function authenticate with the Graph API Interface with the tenant name
    .EXAMPLE
    Get-AuthHeader
    Authenticates you with the Graph API interface
    .NOTES
    NAME: Get-AuthHeader
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Token
    )
    
    $authHeader = @{
        'Content-Type'  = 'application/json'
        'Authorization' = "Bearer " + $Token        
    }
    return $authHeader        
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
        [hashtable]$AuthHeader
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
            Invoke-RestMethod -Uri $uri -Headers $AuthHeader -Method Post -Body $JSON -ContentType "application/json" | Out-Null
        }
    }
    catch {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Error $responseBody 
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
        [hashtable]$AuthHeader
    )

    $graphApiVersion = "v1.0"
    $Resource = "deviceManagement/deviceCompliancePolicies/$CompliancePolicyId/assign"

    try {
        $JSON = @{
            Assignments = @($ComplianceAssignments)
        } | ConvertTo-Json -depth 5
        Write-Output $JSON
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-RestMethod -Uri $uri -Headers $AuthHeader -Method Post -Body $JSON -ContentType "application/json" | Out-Null
    }

    catch {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Error $responseBody 
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
        [hashtable]$AuthHeader
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
        $responseBody = Invoke-RestMethod -Uri $uri -Headers $AuthHeader -Method Post -Body $jsonCode -ContentType "application/json"
    }
    catch {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Error $responseBody 
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
        [hashtable]$AuthHeader
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
            Invoke-RestMethod -Uri $uri -Headers $AuthHeader -Method Post -Body $JSON -ContentType "application/json" | Out-Null
        }
    }
    catch {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Error $responseBody 
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
        [hashtable]$AuthHeader
    )
    $graphApiVersion = "Beta"
    $DCP_resource = "deviceManagement/groupPolicyConfigurations"

    try {
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
		(Invoke-RestMethod -Uri $uri -Headers $AuthHeader -Method Get).Value | Where-Object { $_.displayName -eq $Name }
    }
    catch {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Error $responseBody 
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
        [hashtable]$AuthHeader
    )

    $graphApiVersion = "Beta"
    $Resource = "deviceManagement/groupPolicyConfigurations/$ConfigurationPolicyId/assignments"

    try {
        if (!$ConfigurationPolicyId) {
            Write-Error "No Configuration Policy Id specified, specify a valid Configuration Policy Id"
            break
        }
        if (!$TargetGroupId) {
            Write-Error "No Target Group Id specified, specify a valid Target Group Id"
            break
        }
        if (!$Assignment) {
            Write-Error "No Assignment Type specified, specify a valid Assignment Type"
            break
        }
        $JSON = @{
            target = @{
                "@odata.type" = "#microsoft.graph.$Assignment"
                groupId       = $TargetGroupId
            }
        } | ConvertTo-Json

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-RestMethod -Uri $uri -Headers $AuthHeader -Method Post -Body $JSON -ContentType "application/json" | Out-Null
    }
    catch {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Error $responseBody 
    }
}

Function Get-DeviceManagementScript {
    <#
    .SYNOPSIS
    This function is used to get device management scripts from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any device management scripts
    .EXAMPLE
    Get-DeviceManagementScript
    Returns any device management scripts configured in Intune
    .NOTES
    NAME: Get-DeviceManagementScript
    #>
    [cmdletbinding()]
    param(
        $name,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [hashtable]$AuthHeader
    )
    $graphApiVersion = "Beta"
    $DCP_resource = "deviceManagement/deviceManagementScripts"
    try {
        if ($Name) {
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
            $DevMgmtScript = (Invoke-RestMethod -Uri $uri -Headers $AuthHeader -Method Get).Value | Where-Object { ($_.'displayName').contains($Name) }
            if ($DevMgmtScript) {
                $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)/$($DevMgmtScript.id)"
                Invoke-RestMethod -Uri $uri -Headers $AuthHeader -Method Get
            }
        }
        else {
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
            (Invoke-RestMethod -Uri $uri -Headers $AuthHeader -Method Get).Value
        }
    }
    catch {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Error $responseBody 
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
    param(
        $JSON,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [hashtable]$AuthHeader
    )

    # $B64File = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($File))

    $graphApiVersion = "Beta"
    $DMS_resource = "deviceManagement/deviceManagementScripts"
    Write-Verbose "Resource: $DMS_resource"

    try {
        if ($JSON -eq "" -or $JSON -eq $null) {
            Write-Host "No JSON specified, please specify valid JSON for the Android Policy..." -f Red
        }
        else {
            Test-JSON -JSON $JSON
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($DMS_resource)"
            Invoke-RestMethod -Uri $uri -Headers $AuthHeader -Method Post -Body $JSON -ContentType "application/json"
        }
    }
    catch {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Error $responseBody 
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
        $TargetGroupId,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [hashtable]$AuthHeader
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
            deviceManagementScriptGroupAssignments = @(
                @{
                    "@odata.type" = "#microsoft.graph.deviceManagementScriptGroupAssignment"
                    targetGroupId = $TargetGroupId
                    id            = $ScriptId
                }
            )
        } | ConvertTo-Json

        $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"
        Invoke-RestMethod -Uri $uri -Headers $AuthHeader -Method Post -Body $JSON -ContentType "application/json"
    }
    catch {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Error $responseBody 
    }
}