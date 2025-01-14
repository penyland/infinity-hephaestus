// See https://aka.ms/new-console-template for more information
using Odin.Infrastructure;

var infrastructure = new DevelopmentInfrastructure();

// https://github.com/Azure/azure-sdk-for-net/blob/main/sdk/provisioning/Azure.Provisioning.KeyVault/tests/BasicKeyVaultTests.cs
infrastructure.AddKeyVault();

var provisioningPlan = infrastructure.Build();
provisioningPlan.Compile();
provisioningPlan.Save(".");
