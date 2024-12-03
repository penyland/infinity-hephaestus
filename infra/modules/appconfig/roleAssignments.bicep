metadata name = 'Assign role to Azure App Configuration'
metadata description = 'Create role assignments for Azure App Configuration.'
metadata owner = 'Peter Nylander'
metadata version = '1.0'

import * as types from '../../types/exports.bicep'

@description('Required. Name of the Azure App Configuration instance.')
@minLength(5)
@maxLength(50)
param name string

@description('Optional. Array of role assignments to create.')
param roleAssignments types.roleAssignmentType

var builtInRoleNames = {
  'App Compliance Automation Administrator': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '0f37683f-2463-46b6-9ce7-9b788b988ba2'
  )
  'App Compliance Automation Reader': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    'ffc6bbe0-e443-4c3b-bf54-26581bb2f78e'
  )
  'App Configuration Data Owner': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '5ae67dd6-50cb-40e7-96ff-dc2bfa4b606b'
  )
  'App Configuration Data Reader': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '516239f1-63e1-4d78-a4de-a74fb236a071'
  )
  Contributor: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  Owner: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
  Reader: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  'Role Based Access Control Administrator (Preview)': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    'f58310d9-a9f6-439a-9e8d-f62e7b41a168'
  )
  'User Access Administrator': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9'
  )
}

resource appConfig 'Microsoft.AppConfiguration/configurationStores@2023-03-01' existing = {
  name: name
}

resource registry_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (roleAssignments ?? []): {
    name: guid(appConfig.id, roleAssignment.principalId, roleAssignment.roleDefinitionIdOrName)
    properties: {
      roleDefinitionId: builtInRoleNames[?roleAssignment.roleDefinitionIdOrName] ?? (contains(roleAssignment.roleDefinitionIdOrName, '/providers/Microsoft.Authorization/roleDefinitions/')
            ? roleAssignment.roleDefinitionIdOrName
            : subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleAssignment.roleDefinitionIdOrName))
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: appConfig
  }
]
