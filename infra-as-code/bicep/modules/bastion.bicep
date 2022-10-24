@description('Name of the bastion service')
param name string = ''

@description('Location of the bastion service')
param location string = ''

@description('Id of the subnet that the bastion will be deployed to.')
param bastionSubnetId string = ''

resource publicIp 'Microsoft.Network/publicIpAddresses@2020-05-01' = {
  name: '${name}-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2020-05-01' = {
  name: name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: bastionSubnetId //'${virtualNetwork.id}/subnets/${bastionSubnetName}' 
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}
