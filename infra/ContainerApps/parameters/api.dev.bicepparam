using '../api.bicep'

param otelServiceName = 'TheProjectName:Api'

param containerAppName = 'theprojectname-api-dev'
param containerImage = 'theprojectname/api'
param containerTag = 'latest'
param customContainerName = 'theprojectname-api'
param aspNetCoreEnvironment = 'Development'
param ingressExternal = true

param scaleMinReplicas = 1
param scaleMaxReplicas = 10

param keyVaultName = 'kv-theprojectname-dev-swe'
param storageAccountName = 'st-theprojectname-dev-swe'

param tags = {
  Environment: 'dev'
  Project: 'TheProjectName'
  OTEL_SERVICE_NAME: otelServiceName
}

param platformDependencies = {
  acrConfig: {
    name: 'acr-theplatform-sec'
    resourceGroupName: 'ThePlatformName'
  }

  appConfig: {
    name: 'appcs-theplatform-swe'
    resourceGroupName: 'ThePlatformName'
  }

  managedEnvironment: {
    name: 'cae-theplatform-dev-swe'
    resourceGroupName: 'ThePlatformName'
  }
}
