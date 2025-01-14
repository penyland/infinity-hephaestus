metadata name = 'ThePlatform managed environment deployment'
metadata description = 'Deploys the managed environment for the ThePlatform'
metadata author = 'Peter Nylander'

import * as types from '../types/exports.bicep'

@description('Name of the environment to deploy to. Example: dev, test, prod')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@description('Name of the system. Example: ThePlatformName')
param systemName string

@description('Location of the resources. Example: westeurope')
param location string = resourceGroup().location

@description('Name of the managed container apps environment')
@maxLength(32)
param managedEnvironmentName string = toLower('${systemName}-${environment}-cae')

@description('The resource group for the platform resources.')
param platformDependencies types.platformSettingsType

@description('The current date and time in UTC format. Example: 2021-06-01T1200')
param now string = utcNow('yyyy-MM-ddTHHmm')

@description('Key vault properties')
param keyVault types.keyVaultType

@description('Secrets to be added to the key vault')
param secrets array = []

@description('Deploy secrets to the key vault')
param deploySecrets bool = false

@description('Tags to be added to all resources')
param tags object = {}

var resourceTags = union(tags, {
  Environment: environment
  System: systemName
  LastDeployed: now
})

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: platformDependencies.?logAnalyticsWorkspace.?name ?? 'DefaultWorkspace-${subscription().subscriptionId}-SEC'
  scope: resourceGroup(platformDependencies.?logAnalyticsWorkspace.?resourceGroupName ?? 'DefaultResourceGroup-SEC')
}

module managedEnvironment 'br/public:avm/res/app/managed-environment:0.8.1' = {
  name: '${deployment().name}-cae'
  params: {
    // Required parameters
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.id
    name: toLower('${managedEnvironmentName}')
    // Non-required parameters
    location: location
    infrastructureResourceGroupName: resourceGroup().name
    tags: resourceTags
    zoneRedundant: false
  }
}

module keyvault 'br/public:avm/res/key-vault/vault:0.11.1' = if (!empty(keyVault)) {
  name: '${deployment().name}-kv'
  params: {
    name: keyVault.name
    tags: resourceTags
    secrets: deploySecrets ? secrets : []
    enablePurgeProtection: keyVault.enablePurgeProtection ?? false
    enableSoftDelete: keyVault.enableSoftDelete ?? false
    enableRbacAuthorization: keyVault.enableRbacAuthorization ?? true
    sku: keyVault.sku
    location: location
  }
}

output managedEnvironmentName string = managedEnvironment.outputs.name
output managedEnvironmentResourceId string = managedEnvironment.outputs.resourceId
output defaultDomain string = managedEnvironment.outputs.defaultDomain

output keyVaultName string = !empty(keyVault.name) ? keyvault.outputs.name : ''
output keyVaultUri string = !empty(keyVault) ? keyvault.outputs.uri : ''
