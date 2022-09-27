#!/usr/bin/env bash

set -euo pipefail

# TODO: Ensure this is the correct GitHub homepage where releases can be downloaded for asdf-helper.
GH_REPO="https://github.com/ngyewch/asdf-helper"
TOOL_NAME="asdf-helper"
TOOL_TEST="asdf-helper version"

fail() {
  echo -e "asdf-$TOOL_NAME: $*"
  exit 1
}

curl_opts=(-fsSL)

# NOTE: You might want to remove this if asdf-helper is not hosted on GitHub releases.
if [ -n "${GITHUB_API_TOKEN:-}" ]; then
  curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

sort_versions() {
  sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
    LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
  git ls-remote --tags --refs "$GH_REPO" |
    grep -o 'refs/tags/.*' | cut -d/ -f3- |
    sed 's/^v//' # NOTE: You might want to adapt this sed to remove non-version strings from tags
}

list_all_versions() {
  # TODO: Adapt this. By default we simply list the tag names from GitHub releases.
  # Change this function if asdf-helper has other means of determining installable versions.
  list_github_tags
}

get_arch() {
  arch=$(uname -m | tr '[:upper:]' '[:lower:]')
  case ${arch} in
    arm64)
      arch='arm64'
      ;;
    arm6)
      arch='arm6'
      ;;
    x86_64)
      arch='amd64'
      ;;
    aarch64)
      arch='arm64'
      ;;
    i386)
      arch='i386'
      ;;
  esac

  echo ${arch}
}

get_platform() {
  plat=$(uname | tr '[:upper:]' '[:lower:]')
  case ${plat} in
    darwin)
      plat='darwin'
      ;;
    linux)
      plat='linux'
      ;;
    windows)
      plat='windows'
      ;;
  esac

  echo ${plat}
}

get_ext() {
  plat=$(uname | tr '[:upper:]' '[:lower:]')
  case ${plat} in
    darwin)
      ext='zip'
      ;;
    linux)
      ext='zip'
      ;;
    windows)
      ext='zip'
      ;;
    *)
      ext='zip'
      ;;
  esac

  echo ${ext}
}

download_release() {
  local version filename url
  version="$1"
  filename="$2"

  # TODO: Adapt the release URL convention for asdf-helper
  url="$GH_REPO/releases/download/v${version}/asdf-helper_${version}_$(get_platform)_$(get_arch).$(get_ext)"

  echo "* Downloading $TOOL_NAME release $version..."
  echo "${url}"
  curl "${curl_opts[@]}" -o "$filename" -C - "$url" || fail "Could not download $url"
}

install_version() {
  local install_type="$1"
  local version="$2"
  local install_path="${3%/bin}/bin"

  if [ "$install_type" != "version" ]; then
    fail "asdf-$TOOL_NAME supports release installs only"
  fi

  (
    mkdir -p "$install_path"
    cp -r "$ASDF_DOWNLOAD_PATH"/* "$install_path"

    # TODO: Assert asdf-helper executable exists.
    local tool_cmd
    tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
    test -x "$install_path/$tool_cmd" || fail "Expected $install_path/$tool_cmd to be executable."

    echo "$TOOL_NAME $version installation was successful!"
  ) || (
    rm -rf "$install_path"
    fail "An error occurred while installing $TOOL_NAME $version."
  )
}
