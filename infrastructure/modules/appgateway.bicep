targetScope = 'resourceGroup'

param location string
param tags object
param appGatewaySubnetId string
param appGatewayName string = 'agw-phoenix-prod'
param publicIpName string = 'pip-agw-phoenix-prod'
param wafPolicyName string = 'wafpolicy-phoenix-prod'

// 1. Política WAF dedicada (Estándar moderno exigido por Azure)
resource wafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2023-09-01' = {
  name: wafPolicyName
  location: location
  tags: tags
  properties: {
    policySettings: {
      state: 'Enabled'
      mode: 'Detection'
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
        }
      ]
    }
  }
}

// 2. IP Pública dedicada
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

// 3. Application Gateway L7 vinculado a la WAF Policy
resource appGateway 'Microsoft.Network/applicationGateways@2023-09-01' = {
  name: appGatewayName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: 1
    }
    firewallPolicy: {
      id: wafPolicy.id
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: appGatewaySubnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIp'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'pool-blue'
      }
      {
        name: 'pool-green'
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'httpSettings-port80'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 20
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGatewayName, 'healthProbe-default')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'listener-http'
        properties: {
          frontendIPConfiguration: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/frontendIPConfigurations',
              appGatewayName,
              'appGatewayFrontendIp'
            )
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, 'port_80')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule-http-routing'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName, 'listener-http')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName, 'pool-blue') // Por defecto apunta al entorno Blue
          }
          backendHttpSettings: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
              appGatewayName,
              'httpSettings-port80'
            )
          }
        }
      }
    ]
    probes: [
      {
        name: 'healthProbe-default'
        properties: {
          protocol: 'Http'
          path: '/'
          host: '127.0.0.1'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
          minServers: 0
        }
      }
    ]
  }
}

// Salidas corregidas y mapeadas
output appGatewayId string = appGateway.id
output backendPoolBlueId string = resourceId(
  'Microsoft.Network/applicationGateways/backendAddressPools',
  appGatewayName,
  'pool-blue'
)
output backendPoolGreenId string = resourceId(
  'Microsoft.Network/applicationGateways/backendAddressPools',
  appGatewayName,
  'pool-green'
)
output wafPolicyId string = wafPolicy.id
output publicIpAddressId string = publicIp.id
