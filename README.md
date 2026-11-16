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

# CI

The GitHub Actions workflow (`.github/workflows/build.yml`) runs the scripts in `scripts/cicd/` in order. Each script
can also be run locally from any directory:

| Script            | Purpose                                                                   |
| ----------------- | ------------------------------------------------------------------------- |
| `lint.sh`         | Whitespace and conflict markers, plus `hadolint` on the Dockerfile.       |
| `scan.sh`         | `gitleaks` secret detection and a NuGet vulnerable package audit.         |
| `build.sh`        | Restore, build, and test with coverage (`-p` runs test apps in parallel). |
| `docker-build.sh` | Build the image (tests run in the build stage).                           |
| `docker-test.sh`  | Check the image CMD names the handler and the handler assembly exists.    |
| `scan-image.sh`   | `trivy` HIGH/CRITICAL gate on the built image.                            |

Local runs need `dotnet-coverage`, `gitleaks`, and `trivy` (`hadolint` is optional). Reports land in `artifacts/`.

# References

* https://github.com/serilog/serilog-extensions-logging
* https://docs.aws.amazon.com/lambda/latest/dg/services-sqs-errorhandling.html