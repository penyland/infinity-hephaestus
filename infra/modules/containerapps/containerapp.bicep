metadata name = 'Container App module'
metadata description = 'Create and deploy an Azure Container App'
metadata owner = 'Peter Nylander'

import * as types from '../../types/exports.bicep'

@description('The name of the container app resource.')
param containerAppName string

@description('The resource group for the platform resources.')
param platformDependencies types.platformSettingsType

@description('Optional: Custom name for the container.')
param customContainerName string = ''

@description('The container tag to deploy.')
param containerTag string = ''

@description('The container image to deploy. Defaults to the helloworld image.')
param containerImage string

@description('The container resources. Defaults to 0.25 CPU and 0.5Gi memory.')
param resources types.containerAppResourcesType = {
  cpu: '0.25'
  memory: '0.5Gi'
}

@description('The active revisions mode. Defaults to Single.')
@allowed([
  'Single'
  'Multiple'
])
param activeRevisionsMode string = 'Single'

@description('Whether to allow insecure ingress. Defaults to false.')
param ingressAllowInsecure bool = false

@description('Whether to allow external ingress. Defaults to false.')
param ingressExternal bool = false

@description('The target port for ingress. Defaults to 8080.')
param ingressTargetPort int = 8080

@description('The maximum number of replicas to scale to. Defaults to 10.')
param scaleMaxReplicas int = 10

@description('The minimum number of replicas to scale to. Defaults to 1.')
param scaleMinReplicas int = 1

@description('The sticky sessions affinity. Defaults to None.')
@allowed([
  'none'
  'sticky'
])
param stickySessionsAffinity string = 'none'

@description('The name of the user-assigned identity to use.')
param userAssignedIdentityName string

@description('Optional. List of secrets to add to the container app.')
param secrets array = []

@description('Optional. The ASP.NET Core environment to set. Defaults to Production.')
param aspNetCoreEnvironment string = 'Production'

@description('Optional. List of environment variables to add to the container app.')
param environmentVariables array = []

@description('Optional. Resource tags.')
param tags object = {}

@description('The id of the log analytics workspace.')
param logAnalyticsWorkspaceId string

var managedEnvironmentResourceId = resourceId('Microsoft.App/managedEnvironments', platformDependencies.managedEnvironment.name)

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: userAssignedIdentityName
}

module acrRoleAssignment '../containerregistry/roleAssignments.bicep' = {
  name: '${deployment().name}-acr-rbac'
  scope: resourceGroup(platformDependencies.acrConfig.resourceGroupName)
  params: {
    name: platformDependencies.acrConfig.name
    roleAssignments: [
      {
        principalId: userAssignedIdentity.properties.principalId
        roleDefinitionIdOrName: 'AcrPull'
      }
    ]
  }
}

module appInsights 'br/public:avm/res/insights/component:0.4.2' = {
  name: '${deployment().name}-appi'
  params: {
    name: 'appi-${containerAppName}'
    workspaceResourceId: logAnalyticsWorkspaceId
    tags: tags
    roleAssignments: [
      {
        principalId: userAssignedIdentity.properties.principalId
        roleDefinitionIdOrName: 'Monitoring Metrics Publisher'
      }
    ]
  }
}

module containerApp 'br/public:avm/res/app/container-app:0.11.0' = {
  name: '${deployment().name}-ca'
  params: {
    name: 'ca-${containerAppName}'
    environmentResourceId: managedEnvironmentResourceId
    tags: tags
    containers: [
      {
        name: customContainerName
        image: empty(platformDependencies.acrConfig.name) ? '' : '${platformDependencies.acrConfig.name}.azurecr.io/${containerImage}:${containerTag}'
        resources: resources
        env: union([
          { name: 'ASPNETCORE_ENVIRONMENT', value: aspNetCoreEnvironment }
          { name: 'AZURE_CLIENT_ID', value: userAssignedIdentity.properties.clientId } // Must be set if using user-assigned identity
          { name: 'AZURE_TENANT_ID', value: subscription().tenantId } // Must be set if using user-assigned identity
          { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING', secretRef: '${containerAppName}-appinsights-connection-string' }
        ], environmentVariables)
      }
    ]
    registries: empty(platformDependencies.acrConfig.name) ? [] : [
      {
        server: '${platformDependencies.acrConfig.name}.azurecr.io'
        identity: userAssignedIdentity.id
      }
    ]
    activeRevisionsMode: activeRevisionsMode
    ingressAllowInsecure: ingressAllowInsecure
    ingressExternal: ingressExternal
    ingressTargetPort: ingressTargetPort
    stickySessionsAffinity: stickySessionsAffinity
    managedIdentities: {
      userAssignedResourceIds: [
        userAssignedIdentity.id
      ]
    }
    scaleMaxReplicas: scaleMaxReplicas
    scaleMinReplicas: scaleMinReplicas
    secrets: {
      secureList: union([
        {
          name: '${containerAppName}-appinsights-connection-string'
          value: appInsights.outputs.connectionString
        }
      ], secrets)
    }
  }
}

@description('The FQDN of the container app.')
output fqdn string = empty(containerApp.outputs.fqdn) ? '' : containerApp.outputs.fqdn
