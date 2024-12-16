using Amazon.Lambda.SQSEvents;
using Microsoft.Extensions.Logging;
using RedShirt.Example.SqsLambda.Core;

namespace RedShirt.Example.SqsLambda;

public interface ISafeRecordHandler
{
    Task<bool> HandleAsync(SQSEvent.SQSMessage message, CancellationToken cancellationToken = default);
}

internal class SafeRecordHandler(ILogger<SafeRecordHandler> logger, IMessageHandler messageHandler) : ISafeRecordHandler
{
    public async Task<bool> HandleAsync(SQSEvent.SQSMessage message, CancellationToken cancellationToken = default)
    {
        try
        {
            await messageHandler.HandleMessageAsync(message.Body, cancellationToken);
            return true;
        }
        catch (Exception e)
        {
            // ReSharper disable once TemplateIsNotCompileTimeConstantProblem
            logger.LogError(e.Message, e);
            return false;
        }
    }
}