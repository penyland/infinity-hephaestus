using '../helloworld.bicep'

param otelServiceName = 'helloworld'

param containerAppName = 'helloworld-dev'
param containerImage = 'helloworld'
param containerTag = 'latest'
param customContainerName = 'helloworld'
param ingressExternal = false

param scaleMaxReplicas = 1
param scaleMinReplicas = 1

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

