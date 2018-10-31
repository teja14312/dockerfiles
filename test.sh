#!/bin/bash

set -e

if [ -L "$0" ] ; then
    DIR="$(dirname "$(readlink -f "$0")")"
else
    DIR="$(dirname "$0")"
fi

docker pull koalaman/shellcheck:v0.4.6
docker pull lukasmartinelli/hadolint

run_shellcheck()
{
  local script="$1"
  docker run --rm -i koalaman/shellcheck:v0.4.6 --exclude SC1091 - < "$script" && echo "OK"
}
export -f run_shellcheck

echo "travis_fold:start:lint_scripts"
find "$DIR" -type f ! -path "*.git/*" ! -name "*.py" \( \
  -perm +111 -or -name "*.sh" -or -wholename "*usr/local/share/env/*" -or -wholename "*usr/local/share/container/*" \
\) | parallel --no-notice --line-buffer --tag --tagstring "Linting {}:" run_shellcheck
echo "travis_fold:end:lint_scripts"

run_hadolint()
{
  local dockerfile="$1"
  docker run --rm -i lukasmartinelli/hadolint hadolint --ignore DL3008 --ignore DL3002 --ignore DL3003 --ignore DL4001 --ignore DL3007 --ignore SC2016 - < "$dockerfile" && echo "OK"
}
export -f run_hadolint

echo "travis_fold:start:lint_dockerfiles"
find "$DIR" -type f -name "Dockerfile*" ! -name "*.tmpl" | parallel --no-notice --line-buffer --tag --tagstring "Linting {}:" run_hadolint
echo "travis_fold:end:lint_dockerfiles"

# Run unit tests
echo "travis_fold:start:build_ubuntu_image"
docker-compose -f docker-compose.yml -f docker-compose.test.yml build ubuntu
echo "travis_fold:end:build_ubuntu_image"
echo "travis_fold:start:unit_tests"
docker-compose -f docker-compose.yml -f docker-compose.test.yml run --rm tests
echo "travis_fold:end:unit_tests"

run_integration_tests()
{
  local integration_docker_compose="$1"
  echo "Running integration tests for '$integration_docker_compose':"
  docker-compose -f docker-compose.yml -f "$integration_docker_compose" build --parallel integration_tests
  docker-compose -f docker-compose.yml -f "$integration_docker_compose" up --exit-code-from integration_tests integration_tests
  docker-compose -f docker-compose.yml -f "$integration_docker_compose" down -v
}
export -f run_integration_tests

echo "travis_fold:start:integration_tests"
# Run integration tests
find "$DIR" -type f -path "*/tests/integration/docker-compose.yml" | parallel --no-notice --line-buffer --tag --tagstring "Integration {}:" run_integration_tests
echo "travis_fold:end:integration_tests"
