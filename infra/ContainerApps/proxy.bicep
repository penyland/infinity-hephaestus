metadata name = 'theprojectname Container App'
metadata description = 'theprojectname Service Proxy Container App'
metadata owner = 'Peter Nylander'

import * as types from '../types/exports.bicep'

@description('The logical name of the application.')
param otelServiceName string

@description('The name of the container app resource.')
param containerAppName string

@description('Platform dependencies for the container app.')
param platformDependencies types.platformSettingsType

@description('Optional: Custom name for the container.')
param customContainerName string = ''

@description('The container tag to deploy.')
param containerTag string

@description('The container image to deploy. Defaults to the helloworld image.')
param containerImage string = 'theprojectname/proxy'

@description('Whether to allow insecure ingress. Defaults to false.')
param ingressAllowInsecure bool = false

@description('Whether to allow external ingress. Defaults to true.')
param ingressExternal bool = true

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

@description('Optional. The ASP.NET Core environment to set. Defaults to Production.')
param aspNetCoreEnvironment string = 'Production'

@description('The id of the log analytics workspace.')
param logAnalyticsWorkspaceId string = resourceId('Microsoft.OperationalInsights/workspaces', 'DefaultWorkspace-${subscription().subscriptionId}-SEC', 'DefaultResourceGroup-SEC')

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${containerAppName}'
  location: resourceGroup().location
  tags: tags
}

resource appConfigModule 'Microsoft.AppConfiguration/configurationStores@2024-05-01' existing = {
  name: platformDependencies.appConfig.name
  scope: resourceGroup(platformDependencies.appConfig.resourceGroupName)
}

module appConfigKeyValues '../modules/appconfig/keyvalues.bicep' = {
  name: '${deployment().name}-appcs-kv'
  params: {
    name: platformDependencies.appConfig.name
    keyValues: [
      {
        name: 'TheProjectName:Services:proxy:https'
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
        principalType: 'ServicePrincipal'
      }
    ]
  }
  scope: resourceGroup(platformDependencies.appConfig.resourceGroupName)
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
      { name: 'AZURE_APP_CONFIG_ENDPOINT', value: appConfigModule.properties.endpoint }
      { name: 'OTEL_SERVICE_NAME', value: otelServiceName }
    ]
    secrets: union(secrets, [
      {
        name: '${containerAppName}-appinsights-connection-string'
        keyVaultUrl: 'https://${keyVaultName}${az.environment().suffixes.keyvaultDns}/secrets/${containerAppName}-appinsights-connection-string'
        identity: userAssignedIdentity.id
      }
    ])
    scaleMaxReplicas: scaleMaxReplicas
    scaleMinReplicas: scaleMinReplicas
    userAssignedIdentityName: userAssignedIdentity.name
    tags: tags
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

output fqdn string = containerApp.outputs.fqdn
output userAssignedIdentityPrincipalId string = userAssignedIdentity.properties.principalId
output userAssignedIdentityResourceId string = userAssignedIdentity.id
