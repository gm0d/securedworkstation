# Azure Secure Workstation deployment scripts

This repository contains the accompanying scripts to deploy some of the artifacts required to deploy an Azure Secure Workstation, they will deploy

- Azure AD groups
- Compliance Policies
- Configuration Scripts
- Autopilot profiles
- Enrollment status page

Before running the deployment script the latest version of the following modules need to be installed in the system:

- WindowsAutopilotIntune
- Microsoft.Graph

Allow scripts to run on your device
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

# Deployment

[**_masterScript.PS1**](_masterScript.ps1) - This script is used to import the Compliance policies, Configuration profiles used to apply the Privileged Profile settings   


To import the Privileged Profile configuration settings into your tenant, open a Windows PowerShell console and execute
   
```powershell
.\code\_masterScript.ps1
```
    
Log in with an account that has Global Administrator role assigned.

Wait for the import process to complete.

The _masterScript.ps1 file calls the following scripts to import the artifacts


[**Import-CompliancePolicies.ps1**](.\code\Import-CompliancePolicies.ps1) - This scripts imports three device compliance policies for the Privileged profile. Three policies are used to ensure that Conditional Access does not prevent a user from being able to access resources. Refer to [Windows 10 and later settings to mark devices as compliant or not compliant using Intune](https://docs.microsoft.com/en-us/mem/intune/protect/compliance-policy-create-windows)
   
   1. [Privileged Compliance ATP](.\Settings\SAW\JSON\CompliancePolicies\SAW-Compliance-ATP.json) policy is used to feed the Threat Intelligence data from Microsoft Defender for Endpoint into the devices compliance state so its signals can be used as part of the Conditional Access evaluation process.

   2. [Privileged Compliance Delayed](.\Settings\SAW\JSON\CompliancePolicies\SAW-Compliance-Delayed.json) policy applies a more complete set of compliance settings to the device but its application is delayed by 24 hours.  this is because the device health attestation that is required to assess policies like BitLocker and Secure Boot is only calculated once a device has rebooted and then might take a number of hours to process whether the device is compliant or not.

   3. [Privileged Compliance Immediate](.\Settings\SAW\JSON\CompliancePolicies\SAW-Compliance-Immediate.json) policy is used to apply a minimum level of compliance to users and is configured to apply immediately.

[**Import-ConfigurationProfiles.ps1**](Import-ConfigurationProfiles.ps1) - this script is used to import the Device Configuration profiles that harden the Operating System. there are five profiles used:

1. [SAW-Win10-AppLocker-Custom-CSP](.\Settings\SAW\JSON\ConfigurationProfiles\SAW-Win10-AppLocker-Custom-CSP.json) applies the Restricted Execution Model policies in enforced mode. The AppLocker configuration is configured to allow applications to run under C:\Program Files, C:\Program Files (x86) and C:\Windows, with user writable paths under blocked. the characteristics for the AppLocker approach is:
    -  Assumption is that users are non-privileged users.
    -  Wherever a user can write they are blocked from executing
    -  Wherever a user can execute they are blocked from writing
1. [SAW-Win10-Config-Custom-CSP](.\Settings\SAW\JSON\ConfigurationProfiles\SAW-Win10-Config-Custom-CSP.json) Applies configuration service provider (CSP) settings that are not available in the Endpoint Manager UI, refer to [Configuration service provider reference](https://docs.microsoft.com/en-us/windows/client-management/mdm/configuration-service-provider-reference) for the complete list of the CSP settings available.
1. [SAW-Win10-Config-Device-Restrictions-UI](.\Settings\SAW\JSON\ConfigurationProfiles\SAW-Win10-Config-Device-Restrictions-UI.json) applies settings that restrict cloud account use, configure password policy, Microsoft Defender SmartScreen, Microsoft Defender Antivirus.  Refer to [Windows 10 (and newer) device settings to allow or restrict features using Intune](https://docs.microsoft.com/en-us/mem/intune/configuration/device-restrictions-windows-10) for more details of the settings applied using the profile.
1. [SAW-Win10-Config-Endpoint-Protection-UI](.\Settings\SAW\JSON\ConfigurationProfiles\SAW-Win10-Config-Endpoint-Protection-UI.json) applies settings that are used to protect devices in endpoint protection configuration profiles including BitLocker, Device Guard, Microsoft Defender Firewall, Microsoft Defender Exploit Guard, refer to [Windows 10 (and later) settings to protect devices using Intune](https://docs.microsoft.com/en-us/mem/intune/protect/endpoint-protection-windows-10?toc=/intune/configuration/toc.json&bc=/intune/configuration/breadcrumb/toc.json) for more details of the settings applied using the profile.
1. [SAW-Win10-Config-Identity-Protection-UI](.\Settings\SAW\JSON\ConfigurationProfiles\SAW-Win10-Config-Identity-Protection-UI.json) applies the Windows Hello for Business settings to devices, refer to [Windows 10 device settings to enable Windows Hello for Business in Intune](https://docs.microsoft.com/en-us/mem/intune/protect/identity-protection-windows-settings?toc=/intune/configuration/toc.json&bc=/intune/configuration/breadcrumb/toc.json) for more details of the settings applied using the profile.
1. [SAW-Win10-URLLockProxy-UI](.\Settings\SAW\JSON\ConfigurationProfiles\SAW-Win10-URLLockProxy-UI.json) applies the restrictive URL Lock policy to limit the web sites that SAW devices can connect to.
1. [SAW-Win10-Windows-Defender-Firewall-UI](.\Settings\SAW\JSON\ConfigurationProfiles\SAW-Win10-Windows-Defender-Firewall-UI.json) applies a Firewall policy that has the following characteristics - all inbound traffic is blocked including locally defined rules the policy includes two rules to allow Delivery Optimization to function as designed. Outbound traffic is also blocked apart from explicit rules that allow DNS, DHCP, NTP, NSCI, HTTP, and HTTPS traffic. This configuration not only reduces the attack surface presented by the device to the network it limits the outbound connections that the device can establish to only those connections required to administer cloud services.

| Rule | Direction | Action | Application / Service | Protocol | Local Ports | Remote Ports |
| --- | --- | --- | --- | --- | --- | --- |
| World Wide Web Services (HTTP Traffic-out) | Outbound | Allow | All | TCP | All ports | 80 |
| World Wide Web Services (HTTPS Traffic-out) | Outbound | Allow | All | TCP | All ports | 443 |
| Core Networking - Dynamic Host Configuration Protocol for IPv6(DHCPV6-Out) | Outbound | Allow | %SystemRoot%\system32\svchost.exe | TCP | 546| 547 |
| Core Networking - Dynamic Host Configuration Protocol for IPv6(DHCPV6-Out) | Outbound | Allow | Dhcp | TCP | 546| 547 |
| Core Networking - Dynamic Host Configuration Protocol for IPv6(DHCP-Out) | Outbound | Allow | %SystemRoot%\system32\svchost.exe | TCP | 68 | 67 |
| Core Networking - Dynamic Host Configuration Protocol for IPv6(DHCP-Out) | Outbound | Allow | Dhcp | TCP | 68 | 67 |
| Core Networking - DNS (UDP-Out) | Outbound | Allow | %SystemRoot%\system32\svchost.exe | UDP | All Ports | 53 |
| Core Networking - DNS (UDP-Out) | Outbound | Allow | Dnscache | UDP | All Ports | 53 |
| Core Networking - DNS (TCP-Out) | Outbound | Allow | %SystemRoot%\system32\svchost.exe | TCP | All Ports | 53 |
| Core Networking - DNS (TCP-Out) | Outbound | Allow | Dnscache | TCP | All Ports | 53 |
| NSCI Probe (TCP-Out) | Outbound | Allow | %SystemRoot%\system32\svchost.exe | TCP | All ports | 80 |
| NSCI Probe - DNS (TCP-Out) | Outbound | Allow | NlaSvc | TCP | All ports | 80 |
| Windows Time (UDP-Out) | Outbound | Allow | %SystemRoot%\system32\svchost.exe | TCP | All ports | 80 |
| Windows Time Probe - DNS (UDP-Out) | Outbound | Allow | W32Time | UDP | All ports | 123 |
| Delivery Optimization (TCP-In) | Inbound | Allow | %SystemRoot%\system32\svchost.exe | TCP | 7680 | All ports |
| Delivery Optimization (TCP-In) | Inbound | Allow | DoSvc | TCP | 7680 | All ports |
| Delivery Optimization (UDP-In) | Inbound | Allow | %SystemRoot%\system32\svchost.exe | UDP | 7680 | All ports |
| Delivery Optimization (UDP-In) | Inbound | Allow | DoSvc | UDP | 7680 | All ports |

> [!NOTE]
> There are two rules defined for each rule in the Microsoft Defender Firewall configuration. To restrict the inbound and outbound rules to Windows Services, e.g. DNS Client, both the service name, DNSCache, and the executable path, C:\Windows\System32\svchost.exe, need to be defined as separate rule rather than a single rule that is possible using Group Policy.


[**Import-SAW-DeviceConfigurationADMX.ps1**](.\Settings\SAW\JSON\DeviceConfigurationADMX/SAW-Edge%20Version%2085%20-%20Computer.json) this script is used to import the Device Configuration ADMX Template profile that configures Microsoft Edge security settings.

1.  [SAW-Edge Version 85 - Computer](.\Settings\SAW\JSON\DeviceConfigurationADMX/SAW-Edge%20Version%2085%20-%20Computer.json) applies administrative policies that control features in Microsoft Edge version 77 and later, refer to [Microsoft Edge - Policies](https://docs.microsoft.com/en-us/DeployEdge/microsoft-edge-policies) or more details of the settings applied using the profile.

# Updating settings

## AppLocker
The [app locker configuration profile](.\Settings\SAW\JSON\ConfigurationProfiles\SAW-Win10-AppLocker-Custom-CSP.json) has the settings base64 encoded, they can be customized as a one time task directly in the portal after deployment. Additionally XML files with the raw settings have been provided, if settings are modified in the XML files, they will need to be base64 encoded and merged in to the JSON file. A build script has been provided to complete this task.

From the base directory run

```powershell
Invoke-Build
``` 

## Other settings
Similarly to AppLocker, settings for Configuration profiles, compliance policies, Enrollment status page and Autopilot profiles can be modified in the portal after deployment or directly in the JSON files before deployment. For one time changes (specific for a customer) is recommended to do after deployment, and for persistant changes (for all customers) it's recommended to do in the JSON files. These changes should be peer reviewed before commiting them to the main branch.

The following links provide details on the settings available to be configured

[Compliance Policies](https://docs.microsoft.com/en-us/mem/intune/protect/device-compliance-get-started)
[Configuration Profiles](https://docs.microsoft.com/en-us/mem/intune/configuration/custom-settings-windows-10)