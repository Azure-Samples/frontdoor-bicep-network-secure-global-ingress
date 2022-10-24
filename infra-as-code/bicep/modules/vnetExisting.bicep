@description('This is the name of the vnet')
param vnetName string

@description('This is the name of the subnet you want the id for')
param subnetName string

resource vnet 'Microsoft.Network/virtualNetworks@2019-11-01' existing = {
  name: vnetName

  resource subnet 'subnets' existing = {
    name: subnetName
  }
}

output subnetId string = vnet::subnet.id
