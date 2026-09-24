#!/usr/bin/env bash
# Installs the pinned OpenTelemetry Weaver CLI for the host platform.
#
# The version comes from $WEAVER_VERSION when set (the setup-weaver action passes it).
# Otherwise it is read from versions.env at the root of this repo checkout. Downloads the
# official release binary, verifies its sha256 checksum, and installs it to ~/.local/bin
# (or the directory given as the first argument).
#
# Usage: .github/actions/setup-weaver/install-weaver.sh [install-dir]
set -euo pipefail

if [[ -z "${WEAVER_VERSION:-}" ]]; then
  repo_root="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -n "${repo_root}" && -f "${repo_root}/versions.env" ]]; then
    # shellcheck source=/dev/null
    source "${repo_root}/versions.env"
  fi
fi
if [[ -z "${WEAVER_VERSION:-}" ]]; then
  echo "error: WEAVER_VERSION is not set and versions.env could not be found." >&2
  echo "Pass WEAVER_VERSION=<version> or run from a checkout of this repo." >&2
  exit 1
fi
VERSION="${WEAVER_VERSION#v}"
INSTALL_DIR="${1:-${HOME}/.local/bin}"

case "$(uname -s)" in
  Darwin) os="apple-darwin" ;;
  Linux) os="unknown-linux-gnu" ;;
  *)
    echo "error: unsupported OS: $(uname -s)" >&2
    exit 1
    ;;
esac
case "$(uname -m)" in
  arm64 | aarch64) arch="aarch64" ;;
  x86_64 | amd64) arch="x86_64" ;;
  *)
    echo "error: unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

asset="weaver-${arch}-${os}.tar.xz"
url="https://github.com/open-telemetry/weaver/releases/download/v${VERSION}/${asset}"

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

echo "downloading ${url}"
curl -sSfL -o "${tmpdir}/${asset}" "${url}"
curl -sSfL -o "${tmpdir}/${asset}.sha256" "${url}.sha256"

expected="$(awk '{print $1}' "${tmpdir}/${asset}.sha256")"
if command -v sha256sum >/dev/null 2>&1; then
  (cd "${tmpdir}" && echo "${expected}  ${asset}" | sha256sum -c -)
else
  (cd "${tmpdir}" && echo "${expected}  ${asset}" | shasum -a 256 -c -)
fi

tar -xJf "${tmpdir}/${asset}" -C "${tmpdir}"

mkdir -p "${INSTALL_DIR}"
install -m 0755 "${tmpdir}/weaver-${arch}-${os}/weaver" "${INSTALL_DIR}/weaver"
echo "installed weaver ${VERSION} to ${INSTALL_DIR}/weaver"

case ":${PATH}:" in
  *":${INSTALL_DIR}:"*) ;;
  *) echo "warning: ${INSTALL_DIR} is not on PATH." >&2 ;;
esac

"${INSTALL_DIR}/weaver" --version
