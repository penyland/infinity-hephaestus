
@export()
type containerAppResourcesType = {
  @description('CPU and memory limits for the container.')
  cpu: string
  memory: string
}

@export()
type platformSettingsType = {
  @description('The name and resource group of the container registry.')
  acrConfig: resourceSettingsType

  @description('Reference to the app configuration store to use.')
  appConfig: resourceSettingsType
  
  @description('Reference to the log analytics workspace to use.')
  logAnalyticsWorkspace: resourceSettingsType?

  @description('Reference to the managed environment to deploy to.')
  managedEnvironment: resourceSettingsType
}

@export()
type resourceSettingsType = {
  name: string
  resourceGroupName: string
}

@export()
type keyValuesType = {
  @description('The content type of the key-value pair.')
  contentType: string?

  @description('Required. The name of the key-value pair.')
  name: string

  @description('The tags of the key-value pair.')
  tags: object?

  @description('Required. The value of the key-value pair.')
  value: string
}[]


@export()
type roleAssignmentType = {
  @description('Required. The role to assign. You can provide either the display name of the role definition, the role definition GUID, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
  roleDefinitionIdOrName: string

  @description('Required. The principal ID of the principal (user/group/identity) to assign the role to.')
  principalId: string

  @description('Optional. The principal type of the assigned principal ID.')
  principalType: ('ServicePrincipal' | 'Group' | 'User' | 'ForeignGroup' | 'Device')?

  @description('Optional. The description of the role assignment.')
  description: string?

  @description('Optional. The conditions on the role assignment. This limits the resources it can be assigned to. e.g.: @Resource[Microsoft.Storage/storageAccounts/blobServices/containers:ContainerName] StringEqualsIgnoreCase "foo_storage_container".')
  condition: string?

  @description('Optional. Version of the condition.')
  conditionVersion: '2.0'?

  @description('Optional. The Resource Id of the delegated managed identity resource.')
  delegatedManagedIdentityResourceId: string?
}[]?
