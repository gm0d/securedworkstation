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
    $GroupParams = Convert-ObjectToHashtable $_
    New-MgGroup @GroupParams
}

