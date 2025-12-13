
# You can also pull these images from DockerHub amazon/aws-lambda-dotnet:10
FROM public.ecr.aws/lambda/dotnet:10 AS base

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release

WORKDIR /build
COPY src src
COPY test test
COPY *.sln .
COPY global.json .

RUN dotnet restore
RUN dotnet build
ARG TESTS_ENABLE=1
RUN \[ ${TESTS_ENABLE} -ne 1 \] \
  || \
      ([ -d "test" \] \
      && dotnet test )

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN rm -rf test *sln global \
  && dotnet publish "src/RedShirt.Example.SqsLambda/RedShirt.Example.SqsLambda.csproj" -c $BUILD_CONFIGURATION -o /app/publish

FROM base AS final

WORKDIR ${LAMBDA_TASK_ROOT}
COPY --from=publish /app/publish .
  
# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
CMD [ "RedShirt.Example.SqsLambda::RedShirt.Example.SqsLambda.Function::FunctionHandler" ]
