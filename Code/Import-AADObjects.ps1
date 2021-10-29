param (	
	[Parameter(Mandatory = $true)]
    [ValidateScript( {
        if (-Not ($_ | Test-Path) ) {
            throw "File does not exist"
        }
        if (-Not ($_ | Test-Path -PathType leaf) ) {
            throw "The Path argument must be a File."
        }
        return $true
        })]
    [System.IO.FileInfo]$SettingsFile  
)

$AADObjects = Get-Content $SettingsFile | ConvertFrom-Json

# Create AAD groups for Intune
$AADObjects.Groups | ForEach-Object {
    $Body = $PSItem | ConvertTo-Json    
    # AzureAD module is supposed to be able to add rule for Dynamic group, but parameter does not exist, reported in github
    # in the meantime instead of creating a proper function, doing API call directly
    Write-Host "Creating [$($PSItem.displayName)] group" -ForegroundColor Green
    try{
        $uri = "https://graph.microsoft.com/v1.0/groups"
        Invoke-RestMethod -Uri $uri -Headers $AuthToken -Method Post -Body $Body -ContentType "application/json" | Out-Null
    }
    catch{
        Write-Warning "Could not create [$($PSItem.displayName)]"
        $_.Exception
    }    
}

