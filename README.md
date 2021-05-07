# WWAN in WMI
Adds Wireless Wide Area Network information into the Windows Management Interface

## Usage
```powershell
.\Set-WmiWwan.ps1
```

## Deprecation
I want to deprecate this entirely, but Microsoft needs to know people want the functionality natively.
Please vote for the following idea:
- [ConfigMgr](https://configurationmanager.uservoice.com/forums/300492-ideas/suggestions/35013475-inventory-cellular-information)

## ConfigMgr
To gather the information in ConfigMgr, follow these steps.

### Configuration Item
1. Assets and Compliance / Compliance Settings / Configuration Items
1. Create Configuration Item
1. General
   - Name: *Wireless Wide Area Network*
   - Description: *Populates WMI with WWAN details*
   - Type of confugration item: Windows Desktops and Servers (custom)
1. Supported Platforms
   - Windows 8 and above
1. Settings
   - New
   - Name: *Set-WmiWwan*
   - Description: *Populates WMI with WWAN details*
   - Setting type: Script
   - Data type: String
   - Discovery script
   - Add Script... > Open...: [Set-WmiWwan.ps1](Set-WmiWwan.ps1)
1. Complaince Rules
   - None

### Configuration Baseline
1. Assets and Complaince / Compliance Settings / Configruation Baselines
1. Create Configuration Baseline
   - Name: *Wireless Wide Area Network*
   - Description: *Populates WMI with WWAN details*
   - Configuration data
     1. Add > Configruation Items: Wireless Wide Area Network
1. Deploy
   - Collection: Desired collection (I suggest making one for mobile devices)
   - Schedule
     - Simple schedule > Run every: 1 Days

### Hardware Inventory
1. Administration / Client Settings / Default Client Settings / Hardware Inventory / Set Classes...
1. Import...: [WWAN.mof](WWAN.mof)
