using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using RedShirt.Example.SqsLambda.Core.Extensions;

namespace RedShirt.Example.SqsLambda.Implementations.Extensions;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection ConfigureLambdaImplementations(this IServiceCollection services,
        IConfigurationRoot configuration)
    {
        return services
            .ConfigureLambdaCore(configuration);
    }
}