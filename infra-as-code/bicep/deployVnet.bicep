targetScope = 'resourceGroup'

@description('This is the prefix for each Azure resource name')
param assetPrefix string

@description('The location to deploy the vnet, jumpbox and bastion. Default: resourceGroup().location')
param location string

@description('The locations of the storage accounts that contain the websites.')
param storageAccountWebsiteLocations array = [
  'eastus'
  'westus3'
]

var vmadmin = 'azureuser'

@description('The ssh public key for the jumpbox')
@secure()
param jumpboxPublicSshKey string

var resourceGroupName = resourceGroup().name
var bastionSubnetName = 'AzureBastionSubnet'
var jumpboxSubnetName = 'JumpboxSubnet'
var privateEndpointsSubnetName = 'PrivateEndpointsSubnet'

var vnetSettings = {
  name: '${assetPrefix}-vnet'
  location: location
  addressPrefixes: [
    '10.0.0.0/23'
  ]
  subnets: [
    {
      name: 'WorkloadSubnet'
      addressPrefix: '10.0.0.0/24'
    }
    {
      name: privateEndpointsSubnetName
      addressPrefix: '10.0.1.0/27'
    }
    {
      name: bastionSubnetName
      addressPrefix: '10.0.1.64/26'
    }
    {
      name: jumpboxSubnetName
      addressPrefix: '10.0.1.128/28'
    }
  ]
}

module vnet 'modules/vnet.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: vnetSettings.name
  params: {
    vNetSettings: vnetSettings
  }
}

var bastionSubnetId = '${vnet.outputs.vnetId}/subnets/${bastionSubnetName}'
var privateEndpointsSubnetId = '${vnet.outputs.vnetId}/subnets/${privateEndpointsSubnetName}'
var jumpboxSubnetId = '${vnet.outputs.vnetId}/subnets/${jumpboxSubnetName}'

module storageAccounts 'modules/storageAccountsExisting.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'storageAccounts'
  params: {
    assetPrefix: assetPrefix
    storageAccountWebsiteLocations: storageAccountWebsiteLocations
  }
}

module bastion 'modules/bastion.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'bastion'
  params: {
    name: '${assetPrefix}-bastion'
    location: location
    bastionSubnetId: bastionSubnetId
  }
  dependsOn: [
    vnet
  ]
}

module jumpbox 'modules/jumpbox.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'jumpbox'
  params: {
    name: '${assetPrefix}-jumpbox'
    location: location
    jumpboxSubnetId: jumpboxSubnetId
    vmadmin: vmadmin
    publicKey: jumpboxPublicSshKey
  }
  dependsOn: [
    vnet
  ]
}

module storagePe 'modules/storagePrivateEndpoints.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'storagePe'
  params: {
    name: '${assetPrefix}-jumpbox'
    location: location
    subnetId: privateEndpointsSubnetId
    storageSettings: storageAccounts.outputs.storageSettings
    vnetId: vnet.outputs.vnetId
  }
  dependsOn: [
    vnet
    storageAccounts
  ]
}
