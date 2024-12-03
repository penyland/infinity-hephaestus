metadata name = 'API Container App'
metadata description = 'API Container App'
metadata owner = 'Peter Nylander'

import * as types from '../types/exports.bicep'

@description('The logical name of the application.')
param otelServiceName string

@description('The name of the container app resource.')
param containerAppName string

@description('The resource group for the platform resources.')
param platformDependencies types.platformSettingsType

@description('Optional: Custom name for the container.')
param customContainerName string = ''

@description('The container tag to deploy.')
param containerTag string

@description('The container image to deploy.')
param containerImage string = 'api'

@description('Whether to allow insecure ingress. Defaults to false.')
param ingressAllowInsecure bool = false

@description('Whether to allow external ingress. Defaults to true.')
param ingressExternal bool = false

@description('The target port for ingress. Defaults to 8080.')
param ingressTargetPort int = 8080

@description('The maximum number of replicas to scale to. Defaults to 10.')
param scaleMaxReplicas int = 10

@description('The minimum number of replicas to scale to. Defaults to 1.')
param scaleMinReplicas int = 1

@description('Optional. List of secrets to add to the container app.')
param secrets array = []

@description('Optional. Resource tags.')
param tags object = {}

@description('Name of the key vault.')
param keyVaultName string

@description('The name of the storage account.')
param storageAccountName string

@description('Optional. The ASP.NET Core environment to set. Defaults to Production.')
param aspNetCoreEnvironment string = 'Production'

@description('The id of the log analytics workspace.')
param logAnalyticsWorkspaceId string = resourceId('Microsoft.OperationalInsights/workspaces', 'DefaultWorkspace-${subscription().subscriptionId}-SEC', 'DefaultResourceGroup-SEC')

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${containerAppName}'
  location: resourceGroup().location
  tags: tags
}

resource appConfig 'Microsoft.AppConfiguration/configurationStores@2024-05-01' existing = if (!empty(platformDependencies.appConfig)) {
  name: platformDependencies.appConfig.name
  scope: resourceGroup(platformDependencies.appConfig.resourceGroupName)
}

module appConfigKeyValues '../modules/appconfig/keyvalues.bicep' = {
  name: '${deployment().name}-appcs-kv'
  params: {
    name: platformDependencies.appConfig.name
    keyValues: [
      {
        name: 'TheProjectName:Proxy:Services:api:https'
        value: 'https://${containerApp.outputs.fqdn}'
      }
    ]
  }  
  scope: resourceGroup(platformDependencies.appConfig.resourceGroupName)
}

module appConfigRoleAssignments '../modules/appconfig/roleAssignments.bicep' = {
  name: '${deployment().name}-appcs-rbac'
  params: {
    name: platformDependencies.appConfig.name
    roleAssignments: [
      {
        principalId: userAssignedIdentity.properties.principalId
        roleDefinitionIdOrName: 'App Configuration Data Reader'
      }
    ]
  }
  scope: resourceGroup(platformDependencies.appConfig.resourceGroupName)
}

module keyVaultRoleAssignments '../modules/keyvault/roleAssignments.bicep' = {
  name: '${deployment().name}-kv-rbac'
  params: {
    name: keyVaultName
    roleAssignments: [
      {
        principalId: userAssignedIdentity.properties.principalId
        roleDefinitionIdOrName: 'Key Vault Secrets User'
      }
      {
        principalId: userAssignedIdentity.properties.principalId
        roleDefinitionIdOrName: 'Key Vault Reader'
      }
    ]
  }
}

module tableStorage 'br/public:avm/res/storage/storage-account:0.14.3' = {
  name: '${deployment().name}-st'
  params: {
    name: replace('st${storageAccountName}', '-', '')
    tags: tags
    kind: 'StorageV2'
    blobServices: {
      enabled: true
      containers: []
    }
    tableServices: {
      enabled: true
      tables: []
    }
    roleAssignments: [
      {
        principalId: userAssignedIdentity.properties.principalId
        roleDefinitionIdOrName: 'Storage Table Data Contributor'
      }
    ]
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

module containerApp '../modules/containerapps/containerapp.bicep' = {
  name: '${deployment().name}-ca'
  params: {
    containerAppName: containerAppName
    platformDependencies: platformDependencies
    customContainerName: customContainerName
    containerTag: containerTag
    containerImage: containerImage
    ingressAllowInsecure: ingressAllowInsecure
    ingressExternal: ingressExternal
    ingressTargetPort: ingressTargetPort
    aspNetCoreEnvironment: aspNetCoreEnvironment
    environmentVariables: [
      { name: 'AZURE_APP_CONFIG_ENDPOINT', value: appConfig.properties.endpoint }
      { name: 'AZURE_STORAGE_ACCOUNT_PRIMARY_ENDPOINT', value: 'https://${tableStorage.outputs.name}.table.${az.environment().suffixes.storage}' }
      { name: 'OTEL_SERVICE_NAME', value: otelServiceName }
    ]
    scaleMaxReplicas: scaleMaxReplicas
    scaleMinReplicas: scaleMinReplicas
    secrets: union(secrets, [
      {
        name: '${containerAppName}-appinsights-connection-string'
        keyVaultUrl: 'https://${keyVaultName}${az.environment().suffixes.keyvaultDns}/secrets/${containerAppName}-appinsights-connection-string'
        identity: userAssignedIdentity.id
      }
    ])
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    userAssignedIdentityName: userAssignedIdentity.name
    tags: tags
  }
}

output fqdn string = containerApp.outputs.fqdn
output userAssignedIdentityPrincipalId string = userAssignedIdentity.properties.principalId
output userAssignedIdentityResourceId string = userAssignedIdentity.id
output storageAccountFqdn string = tableStorage.outputs.primaryBlobEndpoint
