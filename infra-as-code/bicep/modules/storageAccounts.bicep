@description('This is the prefix for each Azure resource name')
param assetPrefix string

@description('Boolean indicating whether you want to deny traffic by default')
param setDefaultActionDeny bool

@description('Array containing the locations to deploy storage accounts')
param storageAccountWebsiteLocations array 

var skuName = 'Standard_LRS'
var storageAccountWebsiteContainerName  = 'web'

resource storageAccounts 'Microsoft.Storage/storageAccounts@2021-08-01' = [for location in storageAccountWebsiteLocations: {
  name: '${assetPrefix}st${location}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: skuName
  }
  properties: {
    allowBlobPublicAccess: true
    networkAcls: setDefaultActionDeny ? {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
    } : null
  }
}]

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = [for (setting, i) in storageAccountWebsiteLocations: {
  name: '${storageAccounts[i].name}/default/${storageAccountWebsiteContainerName}'
  properties:{
    publicAccess: 'Container'
  }
}]

output storageSettings array = [for (setting, i) in storageAccountWebsiteLocations: {
  blobEndpointHostName: replace(replace(storageAccounts[i].properties.primaryEndpoints.blob, 'https://', ''), '/', '')
  storageResourceId: storageAccounts[i].id
  location: storageAccounts[i].location
}]
