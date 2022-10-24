@description('This is the prefix for each Azure resource name')
param assetPrefix string 

param storageAccountWebsiteLocations array 

resource storageAccounts 'Microsoft.Storage/storageAccounts@2019-06-01' existing = [for location in storageAccountWebsiteLocations: {
  name: '${assetPrefix}st${location}'
}]

output storageSettings array = [for (setting, i) in storageAccountWebsiteLocations: {
  blobEndpointHostName: replace(replace(storageAccounts[i].properties.primaryEndpoints.blob, 'https://', ''), '/', '')
  storageResourceId: storageAccounts[i].id
  location: storageAccounts[i].location
}]
