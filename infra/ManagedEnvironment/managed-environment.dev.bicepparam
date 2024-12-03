using '../ManagedEnvironment/managed-environment.bicep'

param environment = 'dev'

param managedEnvironmentName = 'cae-theplatform-dev-swe'

param keyVaultName = 'kv-cae-theplatform-dev-swe'

param secrets = [
  {
    name: 'ASecretName'
    value: readEnvironmentVariable('A_SECRET_NAME', 'Cannot fetch secret ThePlatformName-ASecretName from KeyVault')
  }
]
