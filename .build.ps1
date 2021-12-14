
$Configuration = 'SAW'
$ProfilesPath = '.\Settings'

task EncodeXMLFiles {
    Get-ChildItem $ProfilesPath | ForEach-Object {        
        $filePath = "$($PSItem.FullName)\JSON\ConfigurationProfiles\$($Configuration)-Win10-AppLocker-Custom-CSP.json"
        if (Test-Path $filePath){
            Write-Host "Applocker found in [$($PSItem.Name)] folder "
            # $AppLockerFilePath = Get-ChildItem $filePath
            $AppLockerCP = Get-Content $filePath | ConvertFrom-Json             

            $newOmaSettings = @()
            foreach ($setting in $AppLockerCP.omaSettings) {                
                $xmlFile = Get-ChildItem $($PSItem.FullName) -Filter $setting.fileName -Recurse | Select-Object -ExpandProperty FullName                
                $B64File = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($xmlFile))
                $setting.value = $B64File
                $newOmaSettings+= $setting
            }
            $AppLockerCP.omaSettings = $newOmaSettings
            $appLockerCp | ConvertTo-Json -Depth 99 | Set-Content $filePath
        }
        else{
            Write-Host "Skipping [$($PSItem.Name)] folder "
        }
        
    }
    
    # Get-ChildItem $xmlPath | ForEach-Object {

    # }
    # $FileName = Get-Item $File | Select-Object -ExpandProperty Name
    # $B64File = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($File))
}

task . EncodeXMLFiles