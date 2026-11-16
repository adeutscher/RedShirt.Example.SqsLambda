# You can also pull these images from DockerHub amazon/aws-lambda-dotnet:10
FROM public.ecr.aws/lambda/dotnet:10 AS base
# Pick up OS security fixes published after the base image was built (scan-image.sh gates on them).
# The image ships microdnf (dnf is a symlink to it). Amazon Linux 2023 locks the repositories to the
# image's release, so --releasever=latest is needed to see newer fixes.
# hadolint ignore=DL3041
RUN microdnf -y --refresh --releasever=latest upgrade \
 && microdnf clean all \
 && rm -rf /var/cache/dnf /var/cache/yum

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release

WORKDIR /build
COPY src src
COPY test test
COPY *.slnx .
COPY global.json .

RUN dotnet restore \
 && dotnet build -c $BUILD_CONFIGURATION
ARG TESTS_ENABLE=1
# hadolint ignore=SC1072,SC2288
RUN \[ ${TESTS_ENABLE} -ne 1 \] \
  || \
      ([ -d "test" \] \
      && dotnet test )

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN rm -rf test/ ./*slnx global.json \
 && dotnet publish "src/RedShirt.Example.SqsLambda/RedShirt.Example.SqsLambda.csproj" -c $BUILD_CONFIGURATION -o /app/publish

FROM base AS final

WORKDIR ${LAMBDA_TASK_ROOT}
COPY --from=publish /app/publish .

# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
CMD [ "RedShirt.Example.SqsLambda::RedShirt.Example.SqsLambda.Function::FunctionHandler" ]
