#!/bin/sh

set -eu

repository_path="${CI_PRIMARY_REPOSITORY_PATH:?CI_PRIMARY_REPOSITORY_PATH is required}"
exec "$repository_path/ci_scripts/ci_post_clone.sh"
