namespace RedShirt.Example.SqsLambda.Core;

public interface IMessageHandler
{
    Task HandleMessageAsync(string message, CancellationToken cancellationToken = default);
}

public class MessageHandler : IMessageHandler
{
    public Task HandleMessageAsync(string message, CancellationToken cancellationToken = default)
    {
        Console.WriteLine($"HandleMessage: {message}");
        return Task.CompletedTask;
    }
}