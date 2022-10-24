targetScope = 'subscription'

@description('The location for the resource group')
param location string

@description('The name for the resource group')
param rgName string

resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  location: location
  name: rgName
}

output rgName string = rg.name
