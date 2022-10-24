@description('This is the prefix for each Azure resource name')
param assetPrefix string = 'bagbyfd'

@description('Settings to create private endpoints for storage accounts.')
param blobOrigins array = [
  {
    blobEndpointHostName: ''
    storageResourceId: ''
    location: ''
  }
]

@description('The name of the SKU to use when creating the Front Door profile. If you use Private Link this must be set to `Premium_AzureFrontDoor`.')
@allowed([
  'Standard_AzureFrontDoor'
  'Premium_AzureFrontDoor'
])
param frontDoorSkuName string

var originForwardingProtocol = 'HttpsOnly'

var privateLinkOriginDetails = [for (origin, i) in blobOrigins: {
  privateLink: {
    id: '${origin.storageResourceId}'
  }
  groupId: 'blob'
  privateLinkLocation: origin.location
  requestMessage: 'Please approve this connection.'
}]

resource profile 'Microsoft.Cdn/profiles@2021-06-01' = {
  name: '${assetPrefix}-fdprofile'
  location: 'global'
  sku: {
    name: frontDoorSkuName
  }
}

resource endpoint 'Microsoft.Cdn/profiles/afdEndpoints@2021-06-01' = {
  name: '${assetPrefix}-fdedpt'
  parent: profile
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}

resource originGroup 'Microsoft.Cdn/profiles/originGroups@2021-06-01' = {
  name: '${assetPrefix}-fdog'
  parent: profile
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 50
    }
  }
}

resource origins 'Microsoft.Cdn/profiles/originGroups/origins@2021-06-01' = [for (setting, i) in blobOrigins: {
  name: 'origin${i}'
  parent: originGroup
  properties: {
    hostName: setting.blobEndpointHostName
    httpPort: 80
    httpsPort: 443
    originHostHeader: setting.blobEndpointHostName
    priority: 1
    weight: 1000
    sharedPrivateLinkResource: frontDoorSkuName == 'Premium_AzureFrontDoor' ? privateLinkOriginDetails[i] : null
  }
}]

resource route 'Microsoft.Cdn/profiles/afdEndpoints/routes@2021-06-01' = {
  name: '${assetPrefix}-fdrt'
  parent: endpoint
  dependsOn: [
    origins
  ] 
  properties: {
    originGroup: {
      id: originGroup.id
    }
    originPath: null
    supportedProtocols: [
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: originForwardingProtocol
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
  }
}
