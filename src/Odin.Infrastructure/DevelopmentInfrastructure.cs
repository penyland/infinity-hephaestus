using Azure.Provisioning.KeyVault;

namespace Odin.Infrastructure;

public class DevelopmentInfrastructure : Azure.Provisioning.Infrastructure
{
    public DevelopmentInfrastructure() : base() { }

    public void AddKeyVault()
    {
        var keyVault = new KeyVaultService("odin_kv");
        keyVault.Properties = new()
        {
            Sku = new()
            {
                Family = KeyVaultSkuFamily.A,
                Name = KeyVaultSkuName.Standard,
            },
            EnableSoftDelete = true,
            EnablePurgeProtection = false,
            EnableRbacAuthorization = true,
        };

        Add(keyVault);
    }
}
