using Microsoft.Extensions.DependencyInjection;
using RedShirt.Example.SqsLambda.Core;

namespace RedShirt.Example.SqsLambda.IntegrationTests.Tests;

public class FunctionTests
{
    [Fact]
    public void Test_DependencyInjection()
    {
        var function = new Function();
        Assert.Null(function.ServiceProvider);

        function.ConfirmDependencyInjection();

        Assert.NotNull(function.ServiceProvider);
        var originalServiceProvider = function.ServiceProvider;

        Assert.True(function.ServiceProvider.GetService<Handler>() is not null, "Could not find handler");
        Assert.True(function.ServiceProvider.GetService<IMessageHandler>() is not null,
            "Could not find message handler");

        function.ConfirmDependencyInjection();
        // Should be unchanged
        Assert.Same(originalServiceProvider, function.ServiceProvider);
    }
}