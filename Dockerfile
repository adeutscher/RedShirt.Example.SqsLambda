
# You can also pull these images from DockerHub amazon/aws-lambda-dotnet:8
FROM public.ecr.aws/lambda/dotnet:8 AS base

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
COPY . /build
WORKDIR /build
RUN dotnet restore
RUN dotnet build
ARG TESTS_ENABLE=1
RUN \[ ${TESTS_ENABLE} -ne 1 \] \
  || ( \
    \[ -d "test" \] \
    && failedTestProjects=0 \
    && for testFile in $(find test/ -iname '*csproj'); do \
      if ! dotnet test "${testFile}"; then \
          failedTestProjects=$((failedTestProjects+1)); break; \
      fi; \
    done \
    && [ "${failedTestProjects:-0}" -eq 0 ] \
  )

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "src/RedShirt.Example.SqsLambda/RedShirt.Example.SqsLambda.csproj" -c $BUILD_CONFIGURATION -o /app/publish

FROM base AS final

WORKDIR ${LAMBDA_TASK_ROOT}
COPY --from=publish /app/publish .
  
# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
CMD [ "RedShirt.Example.SqsLambda::RedShirt.Example.SqsLambda.Function::FunctionHandler" ]
