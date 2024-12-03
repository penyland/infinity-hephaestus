using '../proxy.bicep'

param otelServiceName = 'TheProjectName:Proxy'

param containerAppName = 'theprojectname-proxy-dev'
param containerImage = 'theprojectname/proxy'
param containerTag = 'latest'
param customContainerName = 'theprojectname-proxy'
param aspNetCoreEnvironment = 'Development'
param ingressExternal = true

param scaleMinReplicas = 1
param scaleMaxReplicas = 10

param keyVaultName = 'kv-theprojectname-dev-swe'

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
