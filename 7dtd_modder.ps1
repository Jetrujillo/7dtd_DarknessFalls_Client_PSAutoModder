<#
.SYNOPSIS
  This script is intended to automate the installation of the 7dtd "Darkness Falls" mod.

.DESCRIPTION
  The script supports hard coded values to point to the mod files .zip folder and 7dtd game path.
  The script will perform some variation of the following (depending on hard coded values): 
  verifying steam libraries, finding the location of the game files, backing up game files, 
  downloading the mod if not provided, unpacking and moving mod files to proper locations, 
  and cleanup any dropped files/folders.

.PARAMETER
  None

.INPUTS
  None

.OUTPUTS
  Backup folder and temporary working folder created on user Desktop. You may find these at:
  ~\Desktop\7dtd_bak_yyyyMMddHHmmss\
  ~\Desktop\7dtdModFolder\
  ~\Desktop\7dtdModFolder\darknessfallsa19client-master.zip
  ~\Desktop\7dtdModFolder\darknessfallsa19client-master\

.NOTES
  Version:        1.0
  Author:         Justin Trujillo
  Creation Date:  08/12/2021
  Purpose/Change: Initial script development
  
.EXAMPLE
  Simply run the script with powershell. If you want/need to point to specific files
  (game or mods), please edit the appropriate variables:

  $pathTo_7dtd - 7dtd Game Folder Path
  $pathTo_A19 - Darkness Falls A19 Path
#>

#----------------------------------------------------------[Declarations]----------------------------------------------------------


## Hard coded path that you can define for the 7dtd game folder. Example below.
# $pathTo_7dtd = "C:\SteamLibrary\steamapps\common\7 Days To Die\"

$pathTo_7dtd = ""

## Hard coded path that you can define for the mod folder. Example below.
# $pathTo_A19 = "C:\path\to\file\download\darknessfallsa19client-master.zip"

$pathTo_A19 = ""

#---------------------------------------------##################################################------------------------------
#---------------------------------------------##!!!!!!!! DO NOT CHANGE ANYTHING BELOW !!!!!!!!##------------------------------
#---------------------------------------------##################################################------------------------------

## Known good direct link to client bundle. As of 8/11/2021, we'll use A19.
$clientURL = "https://gitlab.com/KhaineGB/darknessfallsa19client/-/archive/master/darknessfallsa19client-master.zip"
$clientFileZip = "darknessfallsa19client-master.zip"
$clientFileName = $clientFileZip.Split(".")[0]

#$clientFile = "test.zip"
#$clientURL = "https://www.dundeecity.gov.uk/sites/default/files/publications/civic_renewal_forms.zip"

##Working path
$desktopPath = [Environment]::GetFolderPath("Desktop")
$workingPath = Join-Path $desktopPath "\7dtdModFolder\"


#-----------------------------------------------------------[Functions]------------------------------------------------------------

# Function to validate if a minimum Windows OS build is met.
function ValidateMinOS{
    $build = [System.Environment]::OSVersion.Version.Build
    if ($build -lt 17063){
        Write-Output "Failed minimum OS build requirement."
        Write-Output "Current build: $build"
        Write-Output "Desired build: 17063+"
        exit 
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
function BackupFolder($fullPathFolder){
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $destination = ($desktopPath + "\7dtd_bak_" + $timestamp)
    Copy-Item -Path $fullPathFolder -Destination $destination -Recurse
    return $destination
}

## Function to download the client mod bundle.
function DownloadClientBundle($url){
    New-Item -ItemType Directory -Force -Path $workingPath
    $destination = Join-Path $workingPath $clientFileZip
    wget -Uri $url -UseBasicParsing -OutFile $destination
    return $destination
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

## Values grabbed and staged from above functions. Used in logic below.
$library = Check-MultLibrary
$libMatches = $library.Matches
$libCount = $libMatches.Count
$hardcode_7dtd = Check-HardCode($pathTo_7dtd)
$hardcode_A19 = Check-HardCode($pathTo_A19)
$7dtd_folder = Get-Folder_7dtd

## If downloading Tar bundles, requires minimum version.
## Uncomment '#ValidateMinOS' if needed.
#ValidateMinOS

## Determine if hard coded path was provided.
Write-Output "Checking stuff for 7dtd game folder..."
if ($hardcode_7dtd -eq "hardcoded"){
    Write-Output "Hard coded path provided. `n`nUsing the following game path:"
    Write-Output $pathTo_7dtd
    $check = Test-Path $pathTo_7dtd
    if ($check -eq $false){
        Write-Output "`nProvided path could not be found. Please double check the path for errors or remove to infer game location."
        exit
    }
    $7dtd_folder = $pathTo_7dtd
}
## Determine if more than 1 library was found.
elseif ($libCount -gt 1){
    Write-Output "`n--More than 1 steam library found-- `nPlease hard code the exact path where we can find your 7dtd game folder."
    Write-Output "`nBelow are paths where it may exist:"
    foreach ($match in $libMatches){
        $value = $match.Value -replace '\\\\', '\'
        Write-Output ($value + "\steamapps\common\7 Days To Die\")
    }
    exit
}
## Determine if no libraries were found at all.
elseif ($libCount -eq 1 -and $libMatches -eq $null){
    Write-Output "Could not find any steam libraries. Please verify steam is installed and a library exists."
    exit
}
## Last stage, we will infer where the folder is located based since we didn't get caught earlier.
else{
    if ($hardcode_7dtd -eq "not hardcoded"){
        Write-Output "`nUsing Registry Path...`n"
        if ($7dtd_folder -eq "NA"){
            Write-Output "Regardless of previous checks, the 7tdt game folder does not seem to exist."
            exit
        }
        else{
            Write-Output "Found 7dtd game folder: `n$7dtd_folder"
        }
    } 
}

### Checks complete, now to start the modding process

## Backup current game folder for backout-plan
Write-Output "`nBacking up: `n$7dtd_folder"
$backup = BackupFolder($7dtd_folder)
$backupResult = Test-Path $backup

if ($backupResult -eq $false){
    Write-Output "`nBackup was not created for some reason, exiting."
    exit
}
elseif ($backupResult -eq $true){
    Write-Output "`nBackup of 7dtd game folder was created at: `n$backup"
}

## Determine method for client mod files reference. If hard coded path not provided, we will download it.
Write-Output "`nDetermining client mod file stuff..."
$modfiles = ""
if($hardcode_A19 -eq "hardcoded"){
    Write-Output "`nHard coded path provided. Using the following mod file path:"
    Write-Output $pathTo_A19
    $check = Test-Path $pathTo_A19
    if ($check -eq $false){
        Write-Output "`nProvided path could not be found. Please double check the path for errors or remove to force download instead."
        exit
    }
    $modfiles = $pathTo_A19
}
elseif ($hardcode_A19 -eq "not hardcoded"){
    Write-Output "`Hard coded path not provided. Downloading client mod files from: $clientURL"
    $clientDL = DownloadClientBundle($clientURL)
    $clientResult = Test-Path $clientDL
    if ($clientResult -eq $false){
        Write-Output "Client mod files were unable to be found for some reason, exiting."
        exit
    }
    elseif ($clientResult -eq $true){
        Write-Output "Client mod files successfully downloaded and found at: $clientDL"
        $modfiles = $clientDL
    }
}


## Unpack Mod Files and overwite current game location files
Write-Output "`nUnpacking mod files..."
[string]$source = ($workingPath + "\" + $clientFileZip)
Expand-Archive -Path $source -DestinationPath $workingPath -Force

$expandedModFilePath = Join-Path $workingPath $clientFileName
$modFolderList = @('7DaysToDie_Data','Data','Mods')
Write-Output "`nPlacing mod files into game folder..."
foreach ($folder in $modFolderList){
    Write-Output "`nWorking on folder: $folder"
    $modDirFolder = $expandedModFilePath + "\" + $folder
    Copy-Item -Path $modDirFolder -Destination $7dtd_folder -Recurse -Force
    Write-Output "Finished with folder: $folder"
}
Write-Output "`nModding should be completed."

## Cleanup actions
Write-Output "`nCleaning up files..."
Remove-Item -Path $workingPath -Recurse -Force
Write-Output "`nFinished cleaning up files. Goodbye!"