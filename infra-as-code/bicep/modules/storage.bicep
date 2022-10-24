@description('The location into which the Azure Storage resources should be deployed.')
param location string

@description('The name of the Azure Storage account to create. This must be globally unique.')
param accountName string

@description('The name of the SKU to use when creating the Azure Storage account.')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
  'Premium_LRS'
])
param skuName string

@description('The name of the Azure Storage blob container to create.')
param blobContainerName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: accountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: skuName
  }
  properties: {
    networkAcls: {
      defaultAction: 'Deny'
    }
  }
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = {
  name: '${storageAccount.name}/default/${blobContainerName}'
  properties:{
    publicAccess: 'Container'
  }
}

output blobEndpointHostName string = replace(replace(storageAccount.properties.primaryEndpoints.blob, 'https://', ''), '/', '')
output storageResourceId string = storageAccount.id
