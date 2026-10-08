targetScope = 'resourceGroup'

param location string
param tags object
param bastionSubnetId string
param bastionName string = 'bas-phoenix-prod'
param publicIpName string = 'pip-bastion-phoenix-prod'

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: publicIpName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-09-01' = {
  name: bastionName
  location: location
  tags: tags
  sku: {
    name: 'Standard' // Actualizado a Standard
  }
  properties: {
    enableTunneling: true // Habilita conexión SSH nativa
    ipConfigurations: [
      {
        name: 'bastionIpConfig'
        properties: {
          subnet: {
            id: bastionSubnetId
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}

output bastionHostId string = bastion.id
