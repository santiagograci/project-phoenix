targetScope = 'resourceGroup'

param location string
param vnetName string = 'vnet-phoenix-prod'
param addressPrefix string = '10.0.0.0/16'
param tags object

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: 'snet-appgateway'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: 'snet-backend-vmss'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.3.0/24'
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output appGatewaySubnetId string = '${vnet.id}/subnets/snet-appgateway'
output backendSubnetId string = '${vnet.id}/subnets/snet-backend-vmss'
output bastionSubnetId string = '${vnet.id}/subnets/AzureBastionSubnet'
