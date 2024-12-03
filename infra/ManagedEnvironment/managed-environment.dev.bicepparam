using '../ManagedEnvironment/managed-environment.bicep'

param environment = 'dev'

param managedEnvironmentName = 'cae-theplatform-dev-swe'

param keyVaultName = 'kv-sg-pltfsvc-dev-swe'

param secrets = [
  {
    name: 'SlackBotUserOAuthToken'
    value: readEnvironmentVariable('SLACK_BOT_USER_OAUTH_TOKEN', 'Cannot fetch secret ThePlatformName-BotUserOAuthToken from KeyVault')
  }
]
