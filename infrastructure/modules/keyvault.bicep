targetScope = 'resourceGroup'

param location string
param tags object
@description('Nombre único para el Key Vault (máximo 24 caracteres alfanuméricos)')
param keyVaultName string = 'kv-phoenix-${uniqueString(resourceGroup().id)}'
param managedIdentityName string = 'id-phoenix-vmss-prod'

// 1. Identidad Administrada asignada por el usuario (la "cédula" de las VMs)
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
  tags: tags
}

// 2. Azure Key Vault configurado con RBAC nativo (sin Access Policies obsoletas)
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
  }
}

// 3. Asignación de Rol RBAC: 'Key Vault Secrets User' (4633458b-17de-408a-b874-0445c86b69e6)
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, managedIdentity.id, 'KeyVaultSecretsUser')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
output managedIdentityId string = managedIdentity.id
output managedIdentityClientId string = managedIdentity.properties.clientId
