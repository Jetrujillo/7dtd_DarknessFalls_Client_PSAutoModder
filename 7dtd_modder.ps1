<#
.SYNOPSIS
  This script is intended to automate the installation of the 7dtd "Darkness Falls" mod.

.DESCRIPTION
  The script supports hard coded values to point to the mod files .zip folder and 7dtd game path.
  The script will perform some variation of the following (depending on hard coded values): 
  verifying steam installation/libraries, finding the location of the game files, staging new game files, 
  downloading the mod if not provided, unpacking and moving mod files to proper locations, 
  and cleanup any temp files/folders.

.OUTPUTS
  Staged 7DTD-modded game folder and temporary working folder created on user Desktop. You may find these at:
  ~\Desktop\7dtd_modded\
  ~\Desktop\7dtdModFolder\

.NOTES
  Version:        2.1
  Author:         Justin Trujillo
  Creation Date:  10/08/2023
  Purpose/Change: Added support for mod hotfixes.
  
.EXAMPLE
  Simply run the script with powershell. If you want/need to point to specific files
  (game or mods), please pass any value (not blank) to -GameHardCode and/or -ModHardCode.
#>

#----------------------------------------------------------[Declarations]----------------------------------------------------------
Param (   
    [Parameter(Mandatory = $false)]  
    [string]$GameHardCode = $false,

    [Parameter(Mandatory = $false)]
    [string]$ModHardCode = $false
) 

## Hard coded path that you can define for the 7dtd game folder. Example below.
# $pathTo_7dtd = "C:\SteamLibrary\steamapps\common\7 Days To Die\"
$pathTo_7dtd = ""


## Hard coded path that you can define for the mod folder. Example below.
# $pathTo_A19 = "C:\path\to\file\download\darknessfallsa19client-master.zip"

$pathTo_A19 = ""

#---------------------------------------------##################################################------------------------------
#---------------------------------------------##!!!!!!!! DO NOT CHANGE ANYTHING BELOW !!!!!!!!##------------------------------
#---------------------------------------------##################################################------------------------------
#TODO - Add better support for multiple mod versions.

## Known good direct links to client bundle. As of 09/30/2023, we'll use B25.
#$clientURL = "https://gitlab.com/KhaineGB/darknessfallsa19client/-/archive/master/darknessfallsa19client-master.zip"
#$clientURL = "http://darknessfallsmod.co.uk/DF-V5-DEV-B26.zip"
$clientURL = "http://darknessfallsmod.co.uk/DF-V5-DEV-B25.zip"
#$clientFileZip = "darknessfallsa19client-master.zip"
$clientFileZip = "DF-V5-DEV-B25.zip"
$clientFileName = $clientFileZip.Split(".")[0]

$modVersion = "B25"

#$clientFile = "test.zip"
#$clientURL = "https://www.dundeecity.gov.uk/sites/default/files/publications/civic_renewal_forms.zip"

##Working path
$desktopPath = [Environment]::GetFolderPath("Desktop")
$workingPath = Join-Path $desktopPath "\7dtdModFolder\"
$bundlePath = Join-Path $workingPath $clientFileZip
$7dtd_defPath = "C:\Program Files (x86)\Steam\steamapps\common\7 Days To Die\"
$7dtd_defPathTest = Test-Path $7dtd_defPath


#-----------------------------------------------------------[Functions]------------------------------------------------------------

# Function to validate if a minimum Windows OS build is met.
function ValidateMinOS{
    $build = [System.Environment]::OSVersion.Version.Build
    if ($build -lt 17063){
        Write-Output "Failed minimum OS build requirement."
        Write-Output "Current build: $build"
        Write-Output "Desired build: 17063+"
        exit 1
    }
}

## Function to check if hard coded path is provided.
function Check-HardCode($path){
    if ($path -ne ""){
        return "hardcoded"
    }
    else{
        return "not hardcoded"
    }
}

## Function to get file name from windows form prompt.
function Get-WinFormZipFile{  
    [CmdletBinding()]  
    Param (   
        [Parameter(Mandatory = $false)]  
        [string]$WindowTitle = 'Select the non-extracted zip file for the DF mod.',

        [Parameter(Mandatory = $false)]
        [string]$InitialDirectory,  

        [Parameter(Mandatory = $false)]
        [string]$Filter = "Zip (*.zip)|*.zip"
    ) 
    Add-Type -AssemblyName System.Windows.Forms

    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = $WindowTitle
    $openFileDialog.Filter = $Filter
    $openFileDialog.CheckFileExists = $true
    #$openFileDialog.MultiSelect = $true
    if (![string]::IsNullOrWhiteSpace($InitialDirectory)){ 
        $openFileDialog.InitialDirectory = $InitialDirectory
    }
    if ($openFileDialog.ShowDialog().ToString() -eq 'OK') {
        #$selected = @($openFileDialog.Filenames)
        $selected = $openFileDialog.FileName
    }
    
    #clean-up
    $openFileDialog.Dispose()

    return $selected
}

function Get-WinFormDirectory{  
    [CmdletBinding()]  
    Param (   
        [Parameter(Mandatory = $false)]  
        [string]$WindowTitle = 'Select the folder for the main game.',

        [Parameter(Mandatory = $false)]
        [string]$InitialDirectory
    ) 
    Add-Type -AssemblyName System.Windows.Forms

    $openFolderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $openFolderDialog.Description = $WindowTitle
    $openFolderDialog.RootFolder = "MyComputer"
    if (![string]::IsNullOrWhiteSpace($InitialDirectory)){ 
        $openFolderDialog.InitialDirectory = $InitialDirectory
    }
    if ($openFolderDialog.ShowDialog().ToString() -eq 'OK') {
        $selected = $openFolderDialog.SelectedPath
    }
    
    #clean-up
    $openFolderDialog.Dispose()

    return $selected
}

## Function to move mod files to the desired game folder. Specific for B25.
function Copy-ModFiles{
    [CmdletBinding()]  
    Param (   
        [Parameter(Mandatory = $true)]  
        [string]$GameFolder,

        [Parameter(Mandatory = $true)]
        [string]$ModFolder
    ) 

    $DFFiles = (Get-ChildItem -Path (Join-Path $ModFolder "Mods") -File).FullName
    $DFFiles | % {Copy-Item -Path $_ -Destination $GameFolder -Recurse -Force}
    $GameMods = (Join-Path $GameFolder "Mods")
    if (Test-Path $GameMods){
        Write-Host "Removing existing mod folder at: $GameMods"
        Remove-Item -Path $GameMods -Force
    }
    Copy-Item -Path (Join-Path $ModFolder "Mods") -Destination $GameFolder -Recurse -Force
}


## Function to check if multiple steam library locations are used.
function Check-MultLibrary{
    $installDir = Get-ItemProperty -Path HKLM:SOFTWARE\WOW6432Node\Valve\Steam -Name "InstallPath"
    $steamapps01 = ($installDir.InstallPath + "\steamapps\")
    $libraryPath_part = Get-Content "$steamapps01\libraryfolders.vdf" | Select-String -Pattern '(\w\:\\\\)+(([\w\d\s]+)+(\\\\)*)?' -AllMatches
    return $libraryPath_part
}

## Function to check where 7dtd lives, given that 1 steam library instance exists.
function Get-Folder_7dtd{
    $installDir = Get-ItemProperty -Path HKLM:SOFTWARE\WOW6432Node\Valve\Steam -Name "InstallPath"
    $steamapps01 = ($installDir.InstallPath + "\steamapps\")
    $libraryPath_part = Get-Content "$steamapps01\libraryfolders.vdf" | Select-String -Pattern '(\w\:\\\\)+(([\w\d\s]+)+(\\\\)*)?'
    $libraryPath_value = $libraryPath_part.Matches[0].Value -replace '\\\\', '\'
    $libraryPath_valueFull = Join-Path $libraryPath_value "\steamapps\common\7 Days To Die\"
    $testPath = Test-Path $libraryPath_valueFull
    if ($testPath -eq $false){
        return "NA"
    }
    return $libraryPath_valueFull
}

## Function to back up the 7dtd folder and all contents to the desktop.
function Stage-DFGame($MainGameFullPath){
    $destination = Join-Path $desktopPath "\7dtd_modded\7 Days To Die\"
    Copy-Item -Path $MainGameFullPath -Destination $destination -Recurse
    return $destination
}

## Function to download the client mod bundle.
function DownloadClientBundle($url){
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile $bundlePath
    return $bundlePath
}

function Create-DFShortcut{
    [CmdletBinding()]  
    Param (   
        [Parameter(Mandatory = $true)]  
        [string]$GameFolder
    )

    $ICOFile = Join-Path $GameFolder "darknessfalls.ico"
    $GameExe = Join-Path $GameFolder "7DaysToDie.exe"
    $shortcutFile = Join-Path $desktopPath "7DTD - DF Mod.lnk"
    $WScriptShell = New-Object -ComObject WScript.Shell
    $shortcut = $WScriptShell.CreateShortcut($shortcutFile)
    $shortcut.TargetPath = $GameExe
    $shortcut.WorkingDirectory = $GameFolder
    $shortcut.IconLocation = $ICOFile
    $shortcut.Save()
}

function Add-HotFixFiles{
    [CmdletBinding()]  
    Param (   
        [Parameter(Mandatory = $true)]  
        [string]$GameFolder,
        [Parameter(Mandatory = $true)]  
        [string]$WorkPath,
        [Parameter(Mandatory = $true)]  
        [string]$DFVersion
    )

    $DFHotFixes = [System.Collections.Generic.list[object]]::new()
    $hfDF = [PSCustomObject]@{
        DFVersion = ""
        Link = ""
        FileName = ""
        SHA256 = ""
        GameFolderDest = ""
        FileFullPath = ""
    }
    
    #DF B25 HotFixes 1 Files
    if ($DFVersion -ieq "B25"){
        $hfDF.DFVersion = "B25"
        $hfDF.Link = "https://drive.google.com/uc?id=1Do8x2FC843gNTOlxf4ocP6zgZBnuS2J9&export=download"
        $hfDF.FileName = "IDCCoreV2.dll"
        $hfDF.SHA256 = 'D55714E3B213DA25D53ECB99C9AD2EF3CD632AF42DD85D98D6D5957A1C25DF81'
        $hfDF.GameFolderDest = Join-Path $GameFolder "Mods\IDCCore"
        $hfDF.FileFullPath = Join-Path $hfDf.GameFolderDest $($hfDF.FileName)
        $DFHotFixes.Add($hfDF)
    }

    #DF B26 HotFixes 0 Files
    #TODO: If statement for any B26 hotfixes

    #Implement HotFixes
    if ($DFHotFixes.Count -gt 0){
        $ProgressPreference = 'SilentlyContinue'
        foreach ($hf in $DFHotFixes){
            $hfStagedPath = Join-Path $WorkPath $($hf.FileName)
            Invoke-WebRequest -Uri $($hf.Link) -UseBasicParsing -OutFile $hfStagedPath
            if (-not(Test-Path $hfStagedPath) -or -not(Test-Path ($hf.GameFolderDest))){
                Write-Host "Unable to implement hotfix file for some reason. `n $hf" -ForegroundColor Red
                Write-Host ("DownloadFile Check: " + (Test-Path $hfStagedPath)) -ForegroundColor Yellow
                Write-Host ("GameFolderDest Check: " + (Test-Path ($hf.GameFolderDest))) -ForegroundColor Yellow
                return
            }
            else{
                Move-Item -Path $hfStagedPath -Destination $($hf.FileFullPath) -Force
                if ((Get-FileHash -Algorithm SHA256 $($hf.FileFullPath)).Hash -eq $($hf.SHA256)){
                    Write-Host "HotFix implemented - $($hf.FileName)" -ForegroundColor Green
                    return
                }
            }
        }
    }
    return
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

## Values grabbed and staged from above functions. Used in logic below.
$library = Check-MultLibrary
$libMatches = $library.Matches
$libCount = $libMatches.Count
$7dtd_folder = Get-Folder_7dtd

## If downloading Tar bundles, requires minimum version.
## Uncomment '#ValidateMinOS' if needed.
#ValidateMinOS

## Determine if hard coded path was provided.
Write-Output "Checking stuff for 7dtd game folder..."
if ($GameHardCode -ne $false){
    Write-Output "Hard coded path selected. `n`nPrompting to select the 7dtd main folder:"
    $pathTo_7dtd = Get-WinFormDirectory
    $check = Test-Path $pathTo_7dtd
    if (-not($check)){
        Write-Output "`nProvided path could not be found. Please double check the path for errors."
        exit 1
    }
    Set-Variable -Name "7dtd_folder" -Value $pathTo_7dtd
}

## Determine if default path should be used.
elseif($7dtd_defPathTest -eq $true){
    Write-Output "`nFound game at default path. `n`nUsing the following game path:"
    Set-Variable -Name "7dtd_folder" -Value $7dtd_defPath
    Write-Output $7dtd_folder
}

## Determine if more than 1 steam library was found.
elseif ($libCount -gt 1){
    Write-Output "`n--More than 1 steam library found-- `nPlease hard code the exact path where we can find your 7dtd game folder."
    Write-Output "`nBelow are paths where it may exist:"
    foreach ($match in $libMatches){
        $value = $match.Value -replace '\\\\', '\'
        Write-Output ($value + "\steamapps\common\7 Days To Die\")
    }
    exit 1
}

## Determine if no libraries were found at all.
elseif ($libCount -eq 1 -and $libMatches -eq $null){
    Write-Output "Could not find any steam libraries. Please verify steam is installed and a library exists."
    exit 1
}

## Last stage, we will infer where the folder is located since we didn't get caught earlier.
else{
    if ($GameHardCode -eq $false){
        Write-Output "`nUsing Registry Path...`n"
        if ($7dtd_folder -eq "NA"){
            Write-Output "Regardless of previous checks, the 7dtd game folder does not seem to exist."
            exit
        }
        else{
            Write-Output "Found 7dtd game folder: `n$7dtd_folder"
        }
    } 
}

### Checks complete, now to start the modding process

## Copy game folder to desktop to mod and use instead of Steam Paths
Write-Output "`nCopying 7dtd folder to desktop: `n$7dtd_folder"
$stagedGame = Stage-DFGame($7dtd_folder)
$stagedResult = Test-Path $stagedGame

if ($stagedResult){
    Write-Output "`Staging of 7dtd game folder was created at: `n$stagedGame"
}else{
    Write-Output "`nStaging was not created for some reason, exiting."
    exit 1
}

## Determine method for client mod files reference. If hard coded path not provided, we will download it.
Write-Output "`nDetermining client mod file stuff..."
$modfiles = ''
if($ModHardCode -ne $false){
    Write-Output "`nHard coded selected. Prompting to select the zip folder for mod.."
    $pathTo_Mod = Get-WinFormZipFile
    Write-Output $pathTo_Mod
    $check = Test-Path $pathTo_Mod
    if ($check -eq $false){
        Write-Output "`nProvided path could not be found. Please double check the path for errors or remove to force download instead."
        exit 1
    }
    Set-Variable -Name "modfiles" -Value $pathTo_Mod
}
elseif ($ModHardCode -eq $false){
    Write-Output "`Hard coded path not provided. Downloading client mod files from: $clientURL"
	#Assigning to $null prevents powershell output
    $null = New-Item -ItemType Directory -Force -Path $workingPath
    $clientDL = DownloadClientBundle($clientURL)
    $clientResult = Test-Path $clientDL
    if ($clientResult -eq $false){
        Write-Output "Client mod files were unable to be found for some reason, exiting."
        exit
    }
    elseif ($clientResult -eq $true){
        Write-Output "Client mod files successfully downloaded and found at: $clientDL"
        Set-Variable -Name "modfiles" -Value $clientDL
    }
}

# Copy mod files to the game folder and generate a shortcut on the desktop
Write-Output "`nUnpacking mod files..."
[string]$source = $modfiles
$expandedModFilePath = Join-Path $workingPath $clientFileName
try {
    Expand-Archive -Path $source -DestinationPath $expandedModFilePath -Force
}
catch {
    Write-Host "Unpacking the file has failed. Check if it exists or if the result below has multiple paths."
    Write-Host $source
    exit 1
}

Copy-ModFiles -ModFolder $expandedModFilePath -GameFolder $stagedGame
Add-HotFixFiles -GameFolder $stagedGame -WorkPath $workingPath -DFVersion $modVersion
Create-DFShortcut -GameFolder $stagedGame
Write-Output "`nModding should be completed."

## Cleanup actions
Write-Output "`nCleaning up files..."
Remove-Item -Path $workingPath -Recurse -Force
Write-Output "`nFinished cleaning up files. Goodbye!"