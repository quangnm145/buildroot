#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

KERNEL_REPO="https://github.com/quangnm145/linux.git"
KERNEL_DEFAULT_BRANCH="linux-v6.1-rc8-dev"

UBOOT_REPO="https://github.com/quangnm145/u-boot.git"
UBOOT_DEFAULT_BRANCH="rk3576_rock_4d"

DO_KERNEL=false
DO_UBOOT=false
CUSTOM_BRANCH=""

usage() {
    cat <<EOF
Usage:
  ./initEnv.sh [OPTIONS]

Options:
  -k, --kernel              Clone the Linux kernel source
  -u, --uboot               Clone the U-Boot source
  -b, --branch <branch>     Specify the branch for the selected target
  -h, --help                Show this help message

Examples:
  ./initEnv.sh
      Clone both kernel and U-Boot using their default branches.

  ./initEnv.sh -k
      Clone the kernel using:
        ${KERNEL_DEFAULT_BRANCH}

  ./initEnv.sh --uboot
      Clone U-Boot using:
        ${UBOOT_DEFAULT_BRANCH}

  ./initEnv.sh -k -b linux-v6.1-rc8-dev
      Clone the kernel using the specified branch.

  ./initEnv.sh --uboot --branch rk3576_rock_4d
      Clone U-Boot using the specified branch.

Notes:
  - If neither --kernel nor --uboot is specified, both sources are handled.
  - Existing source directories are skipped and will not be updated.
  - Do not use --branch while selecting both --kernel and --uboot,
    because they normally use different branch names.
EOF
}

clone_if_missing() {
    local name="$1"
    local repo="$2"
    local branch="$3"
    local dir="$BASE_DIR/$name"

    if [[ -d "$dir/.git" ]]; then
        echo "==> Skipping $name: repository already exists at $dir"
        return 0
    fi

    if [[ -e "$dir" ]]; then
        echo "ERROR: $dir exists but is not a Git repository."
        echo "Please rename or remove it before running this script again."
        exit 1
    fi

    echo "==> Cloning $name (branch: $branch)"

    git clone \
        --branch "$branch" \
        --single-branch \
        "$repo" \
        "$dir"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -k|--kernel)
            DO_KERNEL=true
            shift
            ;;

        -u|--uboot)
            DO_UBOOT=true
            shift
            ;;

        -b|--branch)
            if [[ $# -lt 2 || "$2" == -* ]]; then
                echo "ERROR: $1 requires a branch name."
                usage
                exit 1
            fi

            CUSTOM_BRANCH="$2"
            shift 2
            ;;

        -h|--help)
            usage
            exit 0
            ;;

        *)
            echo "ERROR: Invalid option: $1"
            usage
            exit 1
            ;;
    esac
done

# No arguments: show usage and exit.
if [[ "$DO_KERNEL" == false && "$DO_UBOOT" == false && -z "$CUSTOM_BRANCH" ]]; then
    usage
    exit 0
fi

# --branch must be used with exactly one target.
if [[ -n "$CUSTOM_BRANCH" && "$DO_KERNEL" == false && "$DO_UBOOT" == false ]]; then
    echo "ERROR: --branch requires either --kernel or --uboot."
    echo
    usage
    exit 1
fi

# A custom branch cannot apply to both kernel and U-Boot.
if [[ -n "$CUSTOM_BRANCH" && "$DO_KERNEL" == true && "$DO_UBOOT" == true ]]; then
    echo "ERROR: --branch can only be used when selecting either kernel or U-Boot."
    echo
    usage
    exit 1
fi

if [[ "$DO_KERNEL" == true ]]; then
    KERNEL_BRANCH="${CUSTOM_BRANCH:-$KERNEL_DEFAULT_BRANCH}"
    clone_if_missing "kernel" "$KERNEL_REPO" "$KERNEL_BRANCH"
fi

if [[ "$DO_UBOOT" == true ]]; then
    UBOOT_BRANCH="${CUSTOM_BRANCH:-$UBOOT_DEFAULT_BRANCH}"
    clone_if_missing "u-boot" "$UBOOT_REPO" "$UBOOT_BRANCH"
fi

echo
echo "Done."
