using Amazon.Lambda.SQSEvents;

namespace RedShirt.Example.SqsLambda;

internal class Handler(ISafeRecordHandler safeRecordHandler)
{
    public Task<SQSBatchResponse> HandleAsync(SQSEvent sqsEvent, CancellationToken cancellationToken = default)
    {
        var tasks = new List<Task<bool>>();

        // ReSharper disable once ForeachCanBeConvertedToQueryUsingAnotherGetEnumerator
        foreach (var record in sqsEvent.Records ?? [])
        {
            tasks.Add(Task.Run(() => safeRecordHandler.HandleAsync(record, cancellationToken), cancellationToken));
        }

        // ReSharper disable once CoVariantArrayConversion
        Task.WaitAll(tasks.ToArray(), cancellationToken);

        var failures = new List<SQSBatchResponse.BatchItemFailure>();

        for (var i = 0; i < tasks.Count; i++)
        {
            if (!tasks[i].Result)
            {
                failures.Add(new SQSBatchResponse.BatchItemFailure
                {
                    ItemIdentifier = sqsEvent.Records![i].MessageId
                });
            }
        }

        return Task.FromResult(new SQSBatchResponse(failures));
    }
}