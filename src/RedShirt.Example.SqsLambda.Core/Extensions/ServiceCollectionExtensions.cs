using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace RedShirt.Example.SqsLambda.Core.Extensions;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection ConfigureLambdaCore(this IServiceCollection services,
        IConfigurationRoot _)
    {
        return services
            .AddSingleton<IMessageHandler, MessageHandler>();
    }
}