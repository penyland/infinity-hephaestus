metadata name = 'Store key values to Azure App Configuration'
metadata description = 'Deploy key-values to Azure App Configuration.'
metadata owner = 'Peter Nylander'
metadata version = '1.0'

import * as types from '../../types/exports.bicep'

targetScope = 'resourceGroup'

@description('Required. Name of the Azure App Configuration instance.')
@minLength(5)
@maxLength(50)
param name string

@description('The key-value pairs to add to the App Configuration store.')
param keyValues types.keyValuesType

resource appConfigParent 'Microsoft.AppConfiguration/configurationStores@2023-09-01-preview' existing = {
  name: name
}

resource key 'Microsoft.AppConfiguration/configurationStores/keyValues@2023-09-01-preview' = [for key in keyValues: {
  name: key.name
  parent: appConfigParent
  properties: {
    tags: key.?tags ?? null
    contentType: key.?contentType ?? null
    value: key.value
  }
}]
