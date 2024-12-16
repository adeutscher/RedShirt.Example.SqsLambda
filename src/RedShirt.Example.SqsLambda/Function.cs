using Amazon.Lambda.Core;
using Amazon.Lambda.Serialization.SystemTextJson;
using Amazon.Lambda.SQSEvents;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using RedShirt.Example.SqsLambda.Extensions;
using RedShirt.Example.SqsLambda.Implementations.Extensions;
using Serilog;

// Assembly attribute to enable the Lambda function's JSON input to be converted into a .NET class.
[assembly: LambdaSerializer(typeof(DefaultLambdaJsonSerializer))]

namespace RedShirt.Example.SqsLambda;

public class Function
{
    internal IServiceProvider? ServiceProvider;

    /// <summary>
    ///     Default constructor. This constructor is used by Lambda to construct the instance. When invoked in a Lambda
    ///     environment
    ///     the AWS credentials will come from the IAM role associated with the function and the AWS region will be set to the
    ///     region the Lambda function is executed in.
    /// </summary>
    public Function()
    {
    }

    internal void ConfirmDependencyInjection()
    {
        /*
         * Important note: Do not attempt to add the ILambdaContext to dependency injection.
         *                  The object is not refreshed with each invocation of the Lambda.
         */

        if (ServiceProvider is not null)
        {
            return;
        }

        var configuration = new ConfigurationBuilder()
            .AddEnvironmentVariablesWithSegmentSupport()
            .Build();

        Log.Logger = new LoggerConfiguration()
            .Enrich.FromLogContext()
            .WriteTo.Console()
            .CreateLogger();

        var provider = new ServiceCollection()
            .AddLogging(loggingBuilder =>
                loggingBuilder.AddSerilog(dispose: true))
            .AddOptions()
            .AddSingleton<Handler>()
            .AddSingleton<ISafeRecordHandler, SafeRecordHandler>()
            .ConfigureLambdaImplementations(configuration)
            .BuildServiceProvider();

        ServiceProvider = provider;
    }

    /// <summary>
    ///     This method is called for every Lambda invocation. This method takes in an SQS event object and can be used
    ///     to respond to SQS messages.
    /// </summary>
    /// <param name="evnt">The event for the Lambda function handler to process.</param>
    /// <param name="context">The ILambdaContext that provides methods for logging and describing the Lambda environment.</param>
    /// <returns></returns>
    public Task<SQSBatchResponse> FunctionHandler(SQSEvent evnt, ILambdaContext context)
    {
        ConfirmDependencyInjection();
        return ServiceProvider!.GetRequiredService<Handler>().HandleAsync(evnt);
    }
}