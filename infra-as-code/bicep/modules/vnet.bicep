@description('The virtual network settings')
param vNetSettings object = {
  name: ''
  location: ''
  addressPrefixes: [
    ''
  ]
  subnets: [
    {
      name: ''
      addressPrefix: ''
    }
  ]
}

resource vnet 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: vNetSettings.name
  location: vNetSettings.location
  properties: {
    addressSpace: {
      addressPrefixes: vNetSettings.addressPrefixes 
    }
    subnets: [for subnet in vNetSettings.subnets: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.addressPrefix
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
          ]
        }
      }]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output vnetSubnets array = vnet.properties.subnets
