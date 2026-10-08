targetScope = 'resourceGroup'

param location string
param tags object
param backendSubnetId string
param backendAddressPoolId string
param managedIdentityId string
param vmssName string
param environmentColor string = 'Blue'
param adminUsername string = 'azureadmin'

@secure()
param adminPassword string = 'PhoenixPass2026!#'

var scriptTemplate = '''#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Project Phoenix - {0}</title>
    <style>
        body {{ font-family: sans-serif; background-color: {1}; color: #f8fafc; text-align: center; padding-top: 10%; }}
        h1 {{ color: #ffffff; }}
        .card {{ background-color: rgba(0,0,0,0.5); padding: 20px; border-radius: 8px; display: inline-block; }}
    </style>
</head>
<body>
    <div class="card">
        <h1>Project Phoenix: Entorno {0}</h1>
        <p>Atendiendo trafico desde el nodo:</p>
        <h2>HOST: \$(hostname)</h2>
        <p>Zero-Trust Architecture | Azure Application Gateway v2</p>
    </div>
</body>
</html>
EOF

echo "healthy" > /var/www/html/health
'''

var bgColor = environmentColor == 'Blue' ? '#1e3a8a' : '#14532d'
var customDataScript = base64(format(scriptTemplate, environmentColor, bgColor))

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2023-09-01' = {
  name: vmssName
  location: location
  tags: tags
  sku: {
    name: 'Standard_D2s_v7'
    tier: 'Standard'
    capacity: 1
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      osProfile: {
        computerNamePrefix: 'phx-vm'
        adminUsername: adminUsername
        adminPassword: adminPassword
        customData: customDataScript
        linuxConfiguration: {
          disablePasswordAuthentication: false
        }
      }
      storageProfile: {
        imageReference: {
          publisher: 'Canonical'
          offer: '0001-com-ubuntu-server-jammy'
          sku: '22_04-lts-gen2'
          version: 'latest'
        }
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: 'Standard_LRS'
          }
        }
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic-phoenix-vmss'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig-backend'
                  properties: {
                    subnet: {
                      id: backendSubnetId
                    }
                    applicationGatewayBackendAddressPools: [
                      {
                        id: backendAddressPoolId
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
    }
  }
}

// Autoescalado
resource autoscale 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: 'autoscale-${vmssName}'
  location: location
  tags: tags
  properties: {
    enabled: true
    targetResourceUri: vmss.id
    profiles: [
      {
        name: 'defaultProfile'
        capacity: {
          minimum: '1'
          maximum: '2'
          default: '1'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricNamespace: 'microsoft.compute/virtualmachinescalesets'
              metricResourceUri: vmss.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 75
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricNamespace: 'microsoft.compute/virtualmachinescalesets'
              metricResourceUri: vmss.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 25
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
        ]
      }
    ]
  }
}

output vmssId string = vmss.id
output vmssName string = vmss.name
