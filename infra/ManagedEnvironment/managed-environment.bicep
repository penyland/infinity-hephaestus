// theprojectname platform services
metadata name = 'ThePlatformNames managed environment deployment'
metadata description = 'Deploys the managed environment for the theprojectname platform services'
metadata author = 'theprojectname Platform Team'

@description('Name of the environment to deploy to. Example: dev, test, prod')
@allowed([
  'dev'
  'ftr'
  'test'
  'prod'
])
param environment string = 'dev'

@description('Name of the system. Example: ThePlatformName')
param systemName string = 'sg-ThePlatformName'

@description('Location of the resources. Example: westeurope')
param location string = resourceGroup().location

@description('Name of the log analytics workspace to be used.')
param logAnalyticsWorkspaceName string = 'DefaultWorkspace-${subscription().subscriptionId}-SEC'

@description('Resource group of the log analytics workspace to be used.')
param logAnalyticsWorkspaceResourceGroup string = 'DefaultResourceGroup-SEC'

@description('Name of the managed container apps environment')
param managedEnvironmentName string = 'cae-${systemName}-${environment}-swe'

@description('The current date and time in UTC format. Example: 2021-06-01T1200')
param now string = utcNow('yyyy-MM-ddTHHmm')

@description('Name of the key vault of the theprojectname platform')
param keyVaultName string

@description('Secrets to be added to the key vault')
param secrets array = []

@description('Deploy secrets to the key vault')
param deploySecrets bool = false

@description('Tags to be added to all resources')
param tags object = {}

var resourceTags = union(tags, {
  Environment: environment
  Project: 'theprojectname'
  System: 'ThePlatformName'
  LastDeployed: now
})

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup(logAnalyticsWorkspaceResourceGroup)
}

module managedEnvironment 'br/public:avm/res/app/managed-environment:0.8.0' = {
  name: 'managedEnvironmentDeployment-${now}'
  params: {
    // Required parameters
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.id
    name: toLower('${managedEnvironmentName}')
    // Non-required parameters
    location: location
    infrastructureResourceGroupName: resourceGroup().name
    tags: tags
    zoneRedundant: false
  }
}

module keyvault 'br/public:avm/res/key-vault/vault:0.9.0' = {
  name: 'keyVaultDeployment-${now}'
  params: {
    name: keyVaultName
    tags: resourceTags
    secrets: deploySecrets ? secrets : []
  }
}

output managedEnvironmentName string = managedEnvironment.outputs.name
output managedEnvironmentResourceId string = managedEnvironment.outputs.resourceId
output defaultDomain string = managedEnvironment.outputs.defaultDomain

output keyVaultName string = keyvault.outputs.name
output keyVaultUri string = keyvault.outputs.uri
