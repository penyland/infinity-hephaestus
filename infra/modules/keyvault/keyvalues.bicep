metadata name = 'Store key values to Azure Key Vault'
metadata description = 'Deploy key-values to Azure Key Vault.'

import * as types from '../../types/exports.bicep'

targetScope = 'resourceGroup'

@description('Required. Name of the Azure Key Vault instance.')
@minLength(5)
@maxLength(50)
param name string

@description('The key-value pairs to add to the Key Vault store.')
param secrets types.keyValuesType

resource keyVaultParent 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: name
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = [
  for secret in secrets: {
    name: secret.name
    parent: keyVaultParent
    properties: {
      contentType: secret.?contentType ?? null
      value: secret.value
    }
  }
]
