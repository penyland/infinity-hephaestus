// See https://aka.ms/new-console-template for more information
using Odin.Infrastructure;

var infrastructure = new DevelopmentInfrastructure();

infrastructure.AddKeyVault();

var provisioningPlan = infrastructure.Build();
provisioningPlan.Compile();
provisioningPlan.Save(".");
