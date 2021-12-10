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
    This function is used to add an Device Configuration Profile using the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and adds a Device Configuration Profile
    .EXAMPLE
    Add-DeviceConfigurationPolicy -JSON $JSON
    Adds a Device Configuration Profile in Intune
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
    This function is used to add a Device Configuration Profile assignment using the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and adds a Device Configuration Profile assignment
    .EXAMPLE
    Add-DeviceConfigurationPolicyAssignment -ConfigurationPolicyId $ConfigurationPolicyId -TargetGroupId $TargetGroupId
    Adds a Device Configuration Profile assignment in Intune
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
    This function is used to add an Device Configuration Profile using the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and adds a Device Configuration Profile
    .EXAMPLE
    Add-DeviceConfigurationPolicy -JSON $JSON
    Adds a Device Configuration Profile in Intune
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
            Write-Error "No JSON specified, please specify valid JSON for the Device Configuration Profile..."
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
    This function is used to add a Device Configuration Profile assignment using the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and adds a Device Configuration Profile assignment
    .EXAMPLE
    Add-DeviceConfigurationPolicyAssignment -ConfigurationPolicyId $ConfigurationPolicyId -TargetGroupId $TargetGroupId
    Adds a Device Configuration Profile assignment in Intune
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
    This function is used to add a Device Configuration Profile assignment using the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and adds a Device Configuration Profile assignment
    .EXAMPLE
    Add-DeviceConfigurationPolicyAssignment -ConfigurationPolicyId $ConfigurationPolicyId -TargetGroupId $TargetGroupId
    Adds a Device Configuration Profile assignment in Intune
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