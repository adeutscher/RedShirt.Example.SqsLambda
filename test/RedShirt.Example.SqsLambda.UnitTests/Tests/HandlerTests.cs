using Amazon.Lambda.SQSEvents;

namespace RedShirt.Example.SqsLambda.UnitTests.Tests;

public class HandlerTests
{
    [Theory]
    [InlineData(2, 1)]
    public async Task TestOneFailure(int numberOfJobs, int badEggIndex)
    {
        var sqsEvent = new SQSEvent
        {
            Records = []
        };

        var safeHandler = new Mock<ISafeRecordHandler>(MockBehavior.Strict);
        var cts = new CancellationTokenSource();

        for (var i = 0; i < numberOfJobs; i++)
        {
            var message = new SQSEvent.SQSMessage
            {
                MessageId = Guid.NewGuid().ToString(),
                Body = Guid.NewGuid().ToString()
            };
            sqsEvent.Records.Add(message);
            if (i == badEggIndex)
            {
                safeHandler.Setup(s => s.HandleAsync(message, cts.Token)).ReturnsAsync(false);
            }
            else
            {
                safeHandler.Setup(s => s.HandleAsync(message, cts.Token)).ReturnsAsync(true);
            }
        }

        var handler = new Handler(safeHandler.Object);
        var result = await handler.HandleAsync(sqsEvent, cts.Token);

        safeHandler.Verify(s => s.HandleAsync(It.IsAny<SQSEvent.SQSMessage>(), It.IsAny<CancellationToken>()),
            Times.Exactly(numberOfJobs));
        safeHandler.Verify(s => s.HandleAsync(It.IsAny<SQSEvent.SQSMessage>(), cts.Token), Times.Exactly(numberOfJobs));
        foreach (var record in sqsEvent.Records)
        {
            safeHandler.Verify(s => s.HandleAsync(record, cts.Token), Times.Once);
        }

        var badEgg = Assert.Single(result.BatchItemFailures);
        Assert.Equal(sqsEvent.Records[badEggIndex].MessageId, badEgg.ItemIdentifier);
    }
}