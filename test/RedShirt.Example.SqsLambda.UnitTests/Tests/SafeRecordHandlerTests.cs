using Amazon.Lambda.SQSEvents;
using Microsoft.Extensions.Logging.Abstractions;
using RedShirt.Example.SqsLambda.Core;

namespace RedShirt.Example.SqsLambda.UnitTests.Tests;

public class SafeRecordHandlerTests
{
    [Fact]
    public async Task HandleAsync_ShouldReturnFalse()
    {
        var messageString = Guid.NewGuid().ToString();

        var messageHandler = new Mock<IMessageHandler>(MockBehavior.Strict);
        messageHandler.Setup(s => s.HandleMessageAsync(messageString, It.IsAny<CancellationToken>()))
            .Returns(() => throw new Exception("BOOM"));

        var safeHandler = new SafeRecordHandler(new NullLogger<SafeRecordHandler>(), messageHandler.Object);

        var cts = new CancellationTokenSource();
        var result = await safeHandler.HandleAsync(new SQSEvent.SQSMessage {Body = messageString}, cts.Token);
        Assert.False(result);

        messageHandler.Verify(m => m.HandleMessageAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()), Times.Once);
        messageHandler.Verify(m => m.HandleMessageAsync(messageString, cts.Token), Times.Once);
    }

    [Fact]
    public async Task HandleAsync_ShouldReturnTrue()
    {
        var messageString = Guid.NewGuid().ToString();

        var messageHandler = new Mock<IMessageHandler>(MockBehavior.Strict);
        messageHandler.Setup(s => s.HandleMessageAsync(messageString, It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        var safeHandler = new SafeRecordHandler(new NullLogger<SafeRecordHandler>(), messageHandler.Object);

        var cts = new CancellationTokenSource();
        var result = await safeHandler.HandleAsync(new SQSEvent.SQSMessage {Body = messageString}, cts.Token);
        Assert.True(result);

        messageHandler.Verify(m => m.HandleMessageAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()), Times.Once);
        messageHandler.Verify(m => m.HandleMessageAsync(messageString, cts.Token), Times.Once);
    }
}