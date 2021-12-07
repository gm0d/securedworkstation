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
        [hashtable]$AuthHeader
    )

    $graphApiVersion = "Beta"
    $DCP_resource = "/deviceManagement/roleScopeTags"
    Write-Verbose "Resource: $DCP_resource"

    try {
        $Body = @{
            "@odata.type" = "#microsoft.graph.roleScopeTag"
            displayName   = $Name
            description   = $Description
            isBuiltIn     = $false
        } | ConvertTo-Json
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
        $Result = Invoke-RestMethod -Uri $uri -Headers $AuthHeader -Method Post -Body $Body -ContentType "application/json"
        return $Result
    }
    catch {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Error $responseBody        
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
        [hashtable]$AuthHeader
    )

    $graphApiVersion = "Beta"
    $DCP_resource = "deviceManagement/roleScopeTags"
    Write-Verbose "Resource: $DCP_resource"

    try {
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
        $Result = Invoke-RestMethod -Uri $uri -Headers $AuthHeader -Method Get -ContentType "application/json"
        if ($Name) {
            return ($Result.value | Where-Object displayName -eq $Name)
        }
        else {
            return $Result.Value
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
        [hashtable]$AuthHeader
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
        [hashtable]$AuthHeader
    )
    $graphApiVersion = "Beta"
    $Resource = "deviceManagement/deviceConfigurations/$ConfigurationPolicyId/assignments"

    try {
        $JSON = @{
            Assignments = @($Assignments)
        } | ConvertTo-Json -depth 5

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
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
        [hashtable]$AuthHeader
    )
    $graphApiVersion = "Beta"
    $DCP_resource = "deviceManagement/deviceConfigurations"
    try {
        if ($Name) {
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
            (Invoke-RestMethod -Uri $uri -Headers $AuthHeader -Method Get).Value | Where-Object { ($_.'displayName').contains("$Name") }
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
        [hashtable]$AuthHeader
    )
    $graphApiVersion = "Beta"
    $Resource = "deviceManagement/deviceCompliancePolicies"

    try {
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            (Invoke-RestMethod -Uri $uri -Headers $AuthHeader -Method Get).Value | Where-Object { ($_.'@odata.type').contains("windows10CompliancePolicy") -and ($_.'displayName').contains($Name) }
    }
    catch {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Error $responseBody 
    }
}