# 7dtd_DarknessFalls_Client_PSAutoModder
Powershell script to automatically backup and mod installation of 7dtd with the Darkness Falls mod.

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

Examples:
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
