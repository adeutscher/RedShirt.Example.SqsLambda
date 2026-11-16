#!/usr/bin/env bash
#
# Docker test stage: smoke-check the image produced by docker-build.sh.
#
# Unit and integration tests already run in the Dockerfile build stage when
# TESTS_ENABLE=1. This script verifies the runtime image artifact is well-formed:
# the CMD names the expected Lambda handler, and the handler assembly is present
# in the task root.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

image_name="${IMAGE_NAME:-redshirt-example-sqslambda}"
image_tag="${IMAGE_TAG:-ci-local}"
image_ref="$image_name:$image_tag"

handler_assembly="RedShirt.Example.SqsLambda"
expected_cmd="[\"${handler_assembly}::RedShirt.Example.SqsLambda.Function::FunctionHandler\"]"

if [[ -f artifacts/image-tag.txt ]]; then
  recorded="$(tr -d '[:space:]' < artifacts/image-tag.txt)"
  if [[ "$recorded" != "$image_ref" ]]; then
    echo "NOTE: artifacts/image-tag.txt is $recorded (using $image_ref from env)" >&2
  fi
fi

echo "==> docker image inspect $image_ref"
docker image inspect "$image_ref" >/dev/null

cmd_json="$(docker image inspect "$image_ref" --format '{{json .Config.Cmd}}')"
echo "==> cmd: $cmd_json"

if [[ "$cmd_json" != "$expected_cmd" ]]; then
  echo "ERROR: unexpected CMD on $image_ref (expected $expected_cmd)." >&2
  exit 1
fi

# The Lambda base image entrypoint dispatches to the runtime, so override it to look at the
# task root. LAMBDA_TASK_ROOT is set by the base image.
echo "==> handler assembly present in task root"
if ! docker run --rm --entrypoint /bin/sh "$image_ref" \
    -c "test -f \"\${LAMBDA_TASK_ROOT}/${handler_assembly}.dll\""; then
  echo "ERROR: ${handler_assembly}.dll not found in LAMBDA_TASK_ROOT on $image_ref." >&2
  exit 1
fi

echo "==> docker test passed"
