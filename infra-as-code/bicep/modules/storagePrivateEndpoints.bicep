@description('Name of the pe')
param name string 

@description('Location of the pe')
param location string 

@description('Id of the vnet.')
param vnetId string 

@description('Id of the subnet that the bastion will be deployed to.')
param subnetId string 

@description('The settings for the storage accounts that were created. They are used to create the PE for the storage accounts and DNS entries.')
param storageSettings array = [
  {
    blobEndpointHostName: ''
    storageResourceId: ''
    location: ''
  }
]

resource privateEndpoints 'Microsoft.Network/privateEndpoints@2021-05-01' = [for (sa, i) in storageSettings: {
  name: '${name}-${sa.location}'
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${name}-${sa.location}'
        properties: {
          privateLinkServiceId: '${sa.storageResourceId}'
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}]

var privateDnsZoneName = 'privatelink.blob.${environment().suffixes.storage}'

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
  properties: {}
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${privateDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource privateDNSZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = [for (sa, i) in storageSettings: {
  name: '${privateEndpoints[i].name}/${sa.location}'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-database-windows-net${sa.location}'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}]
