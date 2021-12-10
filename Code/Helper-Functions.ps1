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