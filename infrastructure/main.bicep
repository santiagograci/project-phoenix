targetScope = 'resourceGroup'

@description('Región de Azure donde desplegaremos los recursos')
param location string = 'eastus2'

@description('Tags requeridos por la gobernanza de Azure Policy')
param tags object = {
  Environment: 'Production'
  Owner: 'SantiagoGraciano'
  CostCenter: 'CC-Engineering-Phoenix'
  Project: 'Project-Phoenix'
}

// 1. Módulo de Red (VNet y Subredes)
module networkModule 'modules/network.bicep' = {
  name: 'networkDeployment'
  params: {
    location: location
    tags: tags
  }
}

// 2. Módulo de Azure Bastion (Zero-Trust Access)
module bastionModule 'modules/bastion.bicep' = {
  name: 'bastionDeployment'
  params: {
    location: location
    tags: tags
    bastionSubnetId: networkModule.outputs.bastionSubnetId
  }
}

// 3. Módulo de Seguridad (Key Vault + User-Assigned Managed Identity)
module keyVaultModule 'modules/keyvault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    location: location
    tags: tags
  }
}

// 4. Módulo de Ingress L7 (Application Gateway v2 + WAF Policy)
module appGatewayModule 'modules/appgateway.bicep' = {
  name: 'appGatewayDeployment'
  params: {
    location: location
    tags: tags
    appGatewaySubnetId: networkModule.outputs.appGatewaySubnetId
  }
}

// 5. VMSS - Entorno Blue (Activo por defecto)
module vmssBlue './modules/vmss.bicep' = {
  name: 'vmssDeploymentBlue'
  params: {
    location: location
    tags: tags
    backendSubnetId: networkModule.outputs.backendSubnetId
    backendAddressPoolId: appGatewayModule.outputs.backendPoolBlueId
    managedIdentityId: keyVaultModule.outputs.managedIdentityId
    vmssName: 'vmss-phoenix-blue'
    environmentColor: 'Blue'
  }
}

// 6. VMSS - Entorno Green (Nuevo)
module vmssGreen './modules/vmss.bicep' = {
  name: 'vmssDeploymentGreen'
  params: {
    location: location
    tags: tags
    backendSubnetId: networkModule.outputs.backendSubnetId
    backendAddressPoolId: appGatewayModule.outputs.backendPoolGreenId
    managedIdentityId: keyVaultModule.outputs.managedIdentityId
    vmssName: 'vmss-phoenix-green'
    environmentColor: 'Green'
  }
}

// Outputs finales de la arquitectura
output vnetId string = networkModule.outputs.vnetId
output backendSubnetId string = networkModule.outputs.backendSubnetId
output bastionHostId string = bastionModule.outputs.bastionHostId
output keyVaultName string = keyVaultModule.outputs.keyVaultName
output managedIdentityId string = keyVaultModule.outputs.managedIdentityId
output appGatewayId string = appGatewayModule.outputs.appGatewayId
output appGatewayPublicIpId string = appGatewayModule.outputs.publicIpAddressId
output vmssBlueId string = vmssBlue.outputs.vmssId
output vmssGreenId string = vmssGreen.outputs.vmssId
