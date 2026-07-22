/*
Virtual Network Module
This module deploys the core network infrastructure with security controls:

1. Address Space:
   - VNet CIDR: 172.16.0.0/16 OR 192.168.0.0/16
   - Agents Subnet: 172.16.0.0/24 OR 192.168.0.0/24
   - Private Endpoint Subnet: 172.16.101.0/24 OR 192.168.1.0/24

2. Security Features:
   - Network isolation
   - Subnet delegation
   - Private endpoint subnet
*/

@description('Azure region for the deployment')
param location string

@description('The name of the virtual network')
param vnetName string = 'agents-vnet-test'

@description('The name of Agents Subnet')
param agentSubnetName string = 'agent-subnet'

@description('The name of Hub subnet')
param peSubnetName string = 'pe-subnet'


@description('Address space for the VNet')
param vnetAddressPrefix string = ''

@description('Address prefix for the agent subnet')
param agentSubnetPrefix string = ''

@description('Address prefix for the private endpoint subnet')
param peSubnetPrefix string = ''

@description('Create optional subnets required by the Windows jumpbox and Azure Bastion.')
param enableJumpbox bool = false

@description('Address prefix for Azure Bastion subnet. Azure Bastion requires the subnet name AzureBastionSubnet and /26 or larger.')
param bastionSubnetPrefix string = ''

@description('The name of the Windows jumpbox subnet')
param jumpboxSubnetName string = 'jumpbox-subnet'

@description('Address prefix for the Windows jumpbox subnet')
param jumpboxSubnetPrefix string = ''

var defaultVnetAddressPrefix = '192.168.0.0/16'
var vnetAddress = empty(vnetAddressPrefix) ? defaultVnetAddressPrefix : vnetAddressPrefix
var agentSubnet = empty(agentSubnetPrefix) ? cidrSubnet(vnetAddress, 24, 0) : agentSubnetPrefix
var peSubnet = empty(peSubnetPrefix) ? cidrSubnet(vnetAddress, 24, 1) : peSubnetPrefix
var bastionSubnet = empty(bastionSubnetPrefix) ? cidrSubnet(vnetAddress, 26, 8) : bastionSubnetPrefix
var jumpboxSubnet = empty(jumpboxSubnetPrefix) ? cidrSubnet(vnetAddress, 24, 2) : jumpboxSubnetPrefix

var baseSubnets = [
  {
    name: agentSubnetName
    properties: {
      addressPrefix: agentSubnet
      delegations: [
        {
          name: 'Microsoft.app/environments'
          properties: {
            serviceName: 'Microsoft.App/environments'
          }
        }
      ]
    }
  }
  {
    name: peSubnetName
    properties: {
      addressPrefix: peSubnet
    }
  }
]

var jumpboxSubnets = enableJumpbox ? [
  {
    name: 'AzureBastionSubnet'
    properties: {
      addressPrefix: bastionSubnet
    }
  }
  {
    name: jumpboxSubnetName
    properties: {
      addressPrefix: jumpboxSubnet
    }
  }
] : []

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddress
      ]
    }
    subnets: concat(baseSubnets, jumpboxSubnets)
  }
}
// Output variables
output peSubnetName string = peSubnetName
output agentSubnetName string = agentSubnetName
output agentSubnetId string = '${virtualNetwork.id}/subnets/${agentSubnetName}'
output peSubnetId string = '${virtualNetwork.id}/subnets/${peSubnetName}'
output bastionSubnetId string = enableJumpbox ? '${virtualNetwork.id}/subnets/AzureBastionSubnet' : ''
output jumpboxSubnetId string = enableJumpbox ? '${virtualNetwork.id}/subnets/${jumpboxSubnetName}' : ''
output bastionSubnetPrefix string = enableJumpbox ? bastionSubnet : ''
output jumpboxSubnetPrefix string = enableJumpbox ? jumpboxSubnet : ''
output virtualNetworkName string = virtualNetwork.name
output virtualNetworkId string = virtualNetwork.id
output virtualNetworkResourceGroup string = resourceGroup().name
output virtualNetworkSubscriptionId string = subscription().subscriptionId
