@description('Name of the jumpbox')
param name string = ''

@description('Location of the jumpbox')
param location string = ''

@description('Id of the subnet that the bastion will be deployed to.')
param jumpboxSubnetId string = ''

@description('Admin user name')
param vmadmin string = ''

@description('Admin user name')
param publicKey string = ''

var networkInterfaceName ='${name}-nic'
resource nic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: jumpboxSubnetId 
          }
          privateIPAllocationMethod: 'Dynamic'

        }
      }
    ]
  }
}

resource ubuntuVM 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_A2_v2'
    }
    osProfile: {
      computerName: '${name}jumpbox'
      adminUsername: vmadmin
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/azureuser/.ssh/authorized_keys'
              keyData: publicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        name: 'name'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

resource ubuntuVMInstallCli 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  parent: ubuntuVM
  name: 'ubuntuVMInstallCli'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      skipDos2Unix: false
      fileUris: [
        'https://raw.githubusercontent.com/RobBagby/network-secure-ingress-sample/main/infra-as-code/scripts/install_cli.sh'
      ]
    }
    protectedSettings: {
      commandToExecute: 'sh install_cli.sh'
    }
  }
}
