# OSDeploy

# Automated Software Installer for MDT/SCCM  

## Overview  
This project allows for seamless software installation during MDT/SCCM imaging by dynamically downloading and installing the latest versions from vendors.  

## Features  
- Install software dynamically during imaging.  
- Sequential installation with logging and summary.  
- Simple dashboard to track installations.  

## How to Use  
1. Clone the repository.  
2. Run `install_apps.ps1` during imaging.  
3. Select the software to install from the list.  

## Updating Software  
Run `tools/update_repo.ps1` to fetch the latest installer URLs.  

## Logs  
Installation logs can be found in the `logs/` folder.  
