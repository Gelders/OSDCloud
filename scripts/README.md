## ## UNDER PROGRESS
# 📂 OSDCloud | scripts | README.md

## Purpose
This directory serves as a library of standalone scripts and custom functions used to manage, configure, and troubleshoot Windows endpoints. These scripts are primarily focused on PowerShell-based automation for OSDCloud, Microsoft Intune, and general modern workplace management.

## Contents


| Category | Description | Resource / Link |
| :--- | :--- | :--- |
| `PowerShell` | Cleanup script to remove folders, scripts and also centralize the logfiles. | [Browse Cleanup](./CleanUp.ps1) |
| `PowerShell` | Core PS1 scripts for OSDCloud customization, hardware checks, and post-deployment tasks. | [Browse PowerShell](./) |
| `Configuration` | Scripts for applying registry tweaks, local policies, and system optimizations. | [Browse Configuration](./) |
| `Deployment` | Task-specific scripts for application packaging and Autopilot maintenance. | [Browse Deployment](./) |


## Key Features
- **Field Tested:** Most scripts originate from real-world technical consultant scenarios ("notes from the field").
- **Modular:** Designed to be easily integrated into existing OSDCloud or Intune environments.
- **Automated:** Focused on reducing repetitive manual tasks during device lifecycle management.

## How to Use
1. **Review:** Always open the script file to understand the logic and variables.
2. **Test:** Run the script in a Sandbox or Lab environment first.
3. **Deploy:** Execute via PowerShell with the appropriate execution policy (e.g., `-ExecutionPolicy Bypass`).

## Disclaimer
These scripts are provided "as-is" for educational purposes. Use them at your own risk. Always ensure you have a backup and have tested the scripts thoroughly before running them in a production environment.
