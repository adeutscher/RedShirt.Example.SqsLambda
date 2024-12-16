# RedShirt.Example.SqsLambda

Template example of an AWS Lambda configured to react to an SQS queue.

Features over baseline AWS template:

* Dependency injection scaffolding
* Environment variable-based configuration
* Multi-threading
* Batch failure handling

# Initialisation

To change the namespace of the Lambda en-masse for your purposes, use the `init-repo.sh` script:

```bash
bash init-repo.sh New.Namespace.Here
```

# References

* https://github.com/serilog/serilog-extensions-logging
* https://docs.aws.amazon.com/lambda/latest/dg/services-sqs-errorhandling.html