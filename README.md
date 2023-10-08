# 7dtd_DarknessFalls_Client_PSAutoModder
Powershell script to automatically backup and mod installation of 7dtd with the Darkness Falls mod.

## Requirements
You'll likely want to run this an an elevated (admin) Powershell session. Additionally, you may need to configure your system to run unsigned/trusted scripts. 

You can do that with the following command:
```
Set-ExecutionPolicy unrestricted
```

As a security precaution, please consider setting the execution to something more restrictive once you are done.

By default, the execution policy is "restricted":
```
Set-ExeuctionPolicy restricted
```

### Mod Specific
Different mod versions will require different versions of the game to be installed.

As of 10/08/2023, that means DF B25 requires "alpha21.1 - Alpha 21.1 Stable".

To switch to a different version of the game:
- Go to your Steam Library
- Right-Click the game listed on the left-hand side "7 Days to Die" > Select "Properties" from the drop-down menu
- Select "Betas" from the menu on the left-hand side
- Change "Beta Participation" by clicking the drop-down menu to the right of it > Select the appropriate version
- You may now need to reinstall the game to finish

## Running the Script
You can generally just run the script and it'll auto-detect and mod the game. Status messages will display in the console window during the process.

### Examples via PowerShell console
Run script to automatically detect current 7DTD game files and auto-download the mod files.
```
.\7dtd_modder.ps1
```

Manually select current 7DTD game files AND pre-downloaded mod files are.
```
.\7dtd_modder.ps1 -GameHardCode "Yes" -ModHardCode "Yes"
```

Automatically detect current 7DTD game location, but manually select pre-downloaded mod files.
```
.\7dtd_modder.ps1 -ModHardCode "Yes"
```

Manually select current 7DTD game location, but automatically download mod files.
```
.\7dtd_modder.ps1 -GameHardCode "Yes"
```
