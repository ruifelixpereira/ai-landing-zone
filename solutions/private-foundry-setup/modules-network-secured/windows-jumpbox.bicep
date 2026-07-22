@description('Azure region for the Windows jumpbox and Bastion resources.')
param location string

@description('Name of the Windows jumpbox virtual machine.')
param jumpboxVmName string

@description('Size of the Windows jumpbox virtual machine.')
param jumpboxVmSize string = 'Standard_B2s'

@description('Admin username for the Windows jumpbox virtual machine.')
param jumpboxAdminUsername string

@secure()
@description('Admin password for the Windows jumpbox virtual machine.')
@minLength(12)
param jumpboxAdminPassword string

@description('Resource ID of the subnet where the Windows jumpbox NIC is deployed.')
param jumpboxSubnetId string

@description('Resource ID of AzureBastionSubnet.')
param bastionSubnetId string

@description('Address prefix of AzureBastionSubnet. Used to restrict inbound RDP to Bastion only.')
param bastionSubnetPrefix string

@description('Name of the Azure Bastion host to create.')
param bastionName string

@description('Azure Bastion SKU.')
@allowed([
  'Basic'
  'Standard'
])
param bastionSku string = 'Basic'

@description('Name of the Standard public IP address used by Azure Bastion.')
param bastionPublicIpName string

@description('Name of the network security group attached to the jumpbox NIC.')
param jumpboxNsgName string

@description('Name of the jumpbox network interface.')
param jumpboxNicName string

@description('Windows Server image SKU for the jumpbox.')
@allowed([
  '2022-datacenter-azure-edition'
  '2022-datacenter'
  '2019-datacenter'
])
param windowsImageSku string = '2022-datacenter-azure-edition'

@description('OS disk storage SKU for the jumpbox.')
@allowed([
  'StandardSSD_LRS'
  'Premium_LRS'
])
param osDiskSku string = 'StandardSSD_LRS'

resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
  name: bastionPublicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2024-07-01' = {
  name: bastionName
  location: location
  sku: {
    name: bastionSku
  }
  properties: {
    ipConfigurations: [
      {
        name: 'bastion-ipconfig'
        properties: {
          subnet: {
            id: bastionSubnetId
          }
          publicIPAddress: {
            id: bastionPublicIp.id
          }
        }
      }
    ]
  }
}

resource jumpboxNsg 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: jumpboxNsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowRdpFromAzureBastionSubnet'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: bastionSubnetPrefix
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowHttpsOutbound'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
        }
      }
    ]
  }
}

resource jumpboxNic 'Microsoft.Network/networkInterfaces@2024-07-01' = {
  name: jumpboxNicName
  location: location
  properties: {
    networkSecurityGroup: {
      id: jumpboxNsg.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: jumpboxSubnetId
          }
        }
      }
    ]
  }
}

resource jumpboxVm 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: jumpboxVmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: jumpboxVmSize
    }
    osProfile: {
      computerName: take(jumpboxVmName, 15)
      adminUsername: jumpboxAdminUsername
      adminPassword: jumpboxAdminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: windowsImageSku
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskSku
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: jumpboxNic.id
          properties: {
            primary: true
          }
        }
      ]
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
  }
}

output jumpboxVmName string = jumpboxVm.name
output jumpboxVmId string = jumpboxVm.id
output bastionName string = bastionHost.name
output bastionId string = bastionHost.id
output jumpboxNicId string = jumpboxNic.id
