param dnsZoneName string
param virtualNetworkId string
param tags object = {}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: dnsZoneName
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: 'privateDnsZoneLink-${take(uniqueString(virtualNetworkId), 13)}'
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: {
      id: virtualNetworkId
    }
    registrationEnabled: false
  }
}
