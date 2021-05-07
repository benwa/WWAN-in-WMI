#Requires -Version 2
<#
.SYNOPSIS
  Exports cellular information to a WMI class
  
.DESCRIPTION
  Writes mobile device information into WMI for ConfigMgr consumption

.NOTES
  Release Date: 2021-05-07
  Author: Bennett Blodinger

.EXAMPLE
  Set-WmiWwan
#>

[CmdletBinding()]

PARAM ()

If ((Get-Service -Name "WwanSvc").Status -ne "Running") {
    Write-Error -Exception 6 -Message "Mobile Broadband Service (wwansvc) is not running" -ErrorAction Stop
} Else {
    $interfaceOutput = netsh mbn show interfaces
    ForEach ($Line In $interfaceOutput) {
        If (-not ([String]::IsNullOrEmpty($Line))) {
            $Line = ($Line -split ":", 2).Trim()
            Switch -Regex ($Line) {
                "^There (is|are) (\d*) interface(s)? on the system" {
                    $numberOfInterfaces = ($Line[0] | Select-String -Pattern "^There (?:is|are) (\d*) interface(?:s)? on the system*").Matches.Groups[1].Value
                }
                "^Name" {
                    $name = $Line[1]
                }
                "^Description" {
                    $description = $Line[1]
                }
                "^GUID" {
                    $guid = $Line[1]
                }
                "^Physical Address" {
                    $physicalAddress = ($Line[1].ToUpper()).Replace(":", "-")
                }
                "^Additional PDP Context" {
                    $additionalPdpContext = $Line[1]
                }
                "^Parent Interface Guid" {
                    $parentInterfaceGuid = $Line[1]
                }
                "^State" {
                    $state = $Line[1]
                }
                "^Device type" {
                    $deviceType = $Line[1]
                }
                "^Cellular class" {
                    $cellularClass = $Line[1]
                }
                "^Device Id" {
                    $deviceId = $Line[1]
                }
                "^Manufacturer" {
                    $manufacturer = $Line[1]
                }
                "^Model" {
                    $model = $Line[1]
                }
                "^Firmware Version" {
                    $firmwareVersion = $Line[1]
                }
                "^Provider Name" {
                    $providerName = $Line[1]
                }
                "^Roaming" {
                    $roaming = $Line[1]
                }
                "^Signal" {
                    $signal = [single]$Line[1].Replace("%", "") / 100
                }
                "^RSSI / RSCP" {
                    $rssiRscp = $Line[1]
                }
            }
        }
    }
    $CellularInterface = [psobject] @{
        Name                 = $name
        Description          = $description
        Guid                 = $guid
        PhysicalAddress      = $physicalAddress
        AdditionalPdpContext = $additionalPdpContext
        ParentInterfaceGuid  = $parentInterfaceGuid
        State                = $state
        DeviceType           = $deviceType
        CellularClass        = $cellularClass
        DeviceId             = $deviceId
        Manufacturer         = $manufacturer
        Model                = $model
        FirmwareVersion      = $firmwareVersion
        ProviderName         = $providerName
        Roaming              = $roaming
        Signal               = $signal
        RssiRscp             = $rssiRscp
    }

    $readyInformationOutput = netsh mbn show readyinfo interface=`"$($CellularInterface.Name)`"
    [String[]] $telephoneNumbers = @()
    ForEach ($Line In $readyInformationOutput) {
        $Line
        If (-not ([String]::IsNullOrEmpty($Line))) {
            $Line = ($Line -split ":", 2).Trim()
            Switch -Regex ($Line) {
                "^State" {
                    $readyInformation_State = $Line[1]
                }
                "^Emergency mode" {
                    $readyInformation_EmergencyMode = $Line[1]
                }
                "^Subscriber Id" {
                    $readyInformation_SubscriberId = $Line[1]
                }
                "^SIM ICC Id" {
                    $readyInformation_SimIccId = $Line[1]
                }
                "^Telephone #(\d*)" {
                    $telephoneNumbers += $Line[1]
                }
            }
        }
    }
    $ReadyInformation = [psobject] @{
        State            = $readyInformation_State
        EmergencyMode    = $readyInformation_EmergencyMode
        SubscriberId     = $readyInformation_SubscriberId
        SimIccId         = $readyInformation_SimIccId
        TelephoneNumbers = $telephoneNumbers
    }

    $CellularInterface | Add-Member -MemberType NoteProperty -Name "ReadyInformation" -Value $ReadyInformation -Force

    Remove-WmiObject "WWAN" -ErrorAction SilentlyContinue
    $wwanClass = New-Object System.Management.ManagementClass("root\cimv2", [String]::Empty, $null)
    $wwanClass["__CLASS"] = "WWAN"

    $wwanClass.Qualifiers.Add("Static", $true)
    $wwanClass.Properties.Add("Name", [System.Management.CimType]::String, $false)
    $wwanClass.Properties.Add("Description", [System.Management.CimType]::String, $false)
    $wwanClass.Properties.Add("Guid", [System.Management.CimType]::String, $false)
    $wwanClass.Properties.Add("PhysicalAddress", [System.Management.CimType]::String, $false)
    $wwanClass.Properties.Add("AdditionalPdpContext", [System.Management.CimType]::String, $false)
    $wwanClass.Properties.Add("ParentInterfaceGuid", [System.Management.CimType]::String, $false)
    $wwanClass.Properties.Add("State", [System.Management.CimType]::String, $false)
    $wwanClass.Properties.Add("DeviceType", [System.Management.CimType]::String, $false)
    $wwanClass.Properties.Add("CellularClass", [System.Management.CimType]::String, $false)
    $wwanClass.Properties.Add("DeviceId", [System.Management.CimType]::String, $false)
    $wwanClass.Properties.Add("Manufacturer", [System.Management.CimType]::String, $false)
    $wwanClass.Properties.Add("Model", [System.Management.CimType]::String, $false)
    $wwanClass.Properties.Add("FirmwareVersion", [System.Management.CimType]::String, $false)
    $wwanClass.Properties.Add("ProviderName", [System.Management.CimType]::String, $false)
    $wwanClass.Properties.Add("Roaming", [System.Management.CimType]::String, $false)
    $wwanClass.Properties.Add("Signal", [System.Management.CimType]::Real32, $false)
    $wwanClass.Properties.Add("RssiRscp", [System.Management.CimType]::String, $false)
    $wwanClass.Properties["DeviceId"].Qualifiers.Add("Key", $true)
    $wwanClass.Put() | Out-Null

    Remove-WmiObject "WWAN_SIM" -ErrorAction SilentlyContinue
    $wwanSimClass = New-Object System.Management.ManagementClass ("root\cimv2", [String]::Empty, $null)
    $wwanSimClass["__CLASS"] = "WWAN_SIM"
    $wwanSimClass.Qualifiers.Add("Static", $true)
    $wwanSimClass.Properties.Add("AdapterGuid", [System.Management.CimType]::String, $false)
    $wwanSimClass.Properties.Add("State", [System.Management.CimType]::String, $false)
    $wwanSimClass.Properties.Add("EmergencyMode", [System.Management.CimType]::String, $false)
    $wwanSimClass.Properties.Add("SubscriberId", [System.Management.CimType]::String, $false)
    $wwanSimClass.Properties.Add("SimIccId", [System.Management.CimType]::String, $false)
    $wwanSimClass.Properties.Add("TelephoneNumbers", [System.Management.CimType]::String, $true)
    $wwanSimClass.Properties["SimIccId"].Qualifiers.Add("Key", $true)
    $wwanSimClass.Put() | Out-Null

    Set-WmiInstance -Path \\.\root\cimv2:WWAN -Arguments @{
        Name                 = $CellularInterface.Name;
        Description          = $CellularInterface.Description;
        Guid                 = $CellularInterface.Guid;
        PhysicalAddress      = $CellularInterface.PhysicalAddress;
        AdditionalPdpContext = $CellularInterface.AdditionalPdpContext;
        ParentInterfaceGuid  = $CellularInterface.ParentInterfaceGuid;
        State                = $CellularInterface.State;
        DeviceType           = $CellularInterface.DeviceType;
        CellularClass        = $CellularInterface.CellularClass;
        DeviceId             = $CellularInterface.DeviceId;
        Manufacturer         = $CellularInterface.Manufacturer;
        Model                = $CellularInterface.Model;
        FirmwareVersion      = $CellularInterface.FirmwareVersion;
        ProviderName         = $CellularInterface.ProviderName;
        Roaming              = $CellularInterface.Roaming;
        Signal               = $CellularInterface.Signal;
        RssiRscp             = $CellularInterface.RssiRscp;
    } | Out-Null

    Set-WmiInstance -Path \\.\root\cimv2:WWAN_SIM -Arguments @{
        AdapterGuid      = $CellularInterface.Guid;
        State            = $CellularInterface.ReadyInformation.State;
        EmergencyMode    = $CellularInterface.ReadyInformation.EmergencyMode;
        SubscriberId     = $CellularInterface.ReadyInformation.SubscriberId;
        SimIccId         = $CellularInterface.ReadyInformation.SimIccId;
        TelephoneNumbers = $CellularInterface.ReadyInformation.TelephoneNumbers;
    } | Out-Null
}
