targetScope = 'subscription'

@description('This is the prefix for each Azure resource name')
@minLength(6) 
@maxLength(12)
param assetPrefix string

@description('The location of the resource group, vnet, jumpbox and bastion.')
param location string = deployment().location

@description('This is an array of valid azure locations where storage accounts will be deployed.')
param storageAccountWebsiteLocations array = [
  'eastus'
  'westus3'
]

@description('The name of the SKU to use when creating the Front Door profile. If you use Private Link this must be set to `Premium_AzureFrontDoor`.')
@allowed([
  'Standard_AzureFrontDoor'
  'Premium_AzureFrontDoor'
])
param frontDoorSkuName string = 'Standard_AzureFrontDoor'

@description('The object id of the logged in user. This user will be given Storage Blob Data Contributor Role Assignment. It can be used to update the website.')
@secure()
param principalId string = ''

var rgName = '${assetPrefix}-rg'
var roleStorageBlobDataContributor = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

module rg 'modules/rg.bicep' = {
  name: rgName
  params: {
    rgName: rgName
    location: location
  }
}

module storageAccounts 'modules/storageAccounts.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'storageAccounts'
  params: {
    assetPrefix: assetPrefix
    setDefaultActionDeny: frontDoorSkuName == 'Premium_AzureFrontDoor'? true : false
    storageAccountWebsiteLocations: storageAccountWebsiteLocations
  }
}

module frontDoor 'modules/frontdoor.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'frontdoor'
  params: {
    frontDoorSkuName: frontDoorSkuName
    assetPrefix: assetPrefix
    blobOrigins: storageAccounts.outputs.storageSettings
  }
}

module storageAccountRoleAssignment 'modules/storageAccountRoleAssignment.bicep' = {
  name: 'storageAccountRoleAssignment'
  scope: resourceGroup(rgName)
  params: {
    principalId: principalId
    roleDefinitionResourceId: roleStorageBlobDataContributor
    assetPrefix: assetPrefix
  }
  dependsOn: [
    rg
  ]
}
