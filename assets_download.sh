#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
base_url="https://github.com/sun-jiao/osea_mobile/releases/download/assets"
files=(db/avonet.db labels/bird_info.json models/bird_model.onnx models/ssd_mobilenet.onnx)
checksums=(
  6dd77175865bbfe034a3aa81bd293cad58ec66b912087727f078d4306086e8a0
  9188461c016c614ba531f6db2c55255588e56bf61baf64aed7249d5b21c6d1a2
  56b8c61e74bc0d764a5ab21ab279857d03d5355152f7bd8c3c70a0c06cd20ce9
  985e611a85dcfcd5b5020a27a1c0b38920107a5d35316abb51a23682a8f13ec9
)

checksum() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

temporary_file=''
trap 'if [[ -n "$temporary_file" ]]; then rm -f -- "$temporary_file"; fi' EXIT
for i in "${!files[@]}"; do
  destination="assets/${files[$i]}"
  if [[ -f "$destination" ]] && [[ "$(checksum "$destination")" == "${checksums[$i]}" ]]; then
    echo "Verified $destination"
    continue
  fi
  mkdir -p -- "$(dirname -- "$destination")"
  temporary_file=$(mktemp "${destination}.download.XXXXXX")
  curl --fail --location --retry 3 --connect-timeout 20 --max-time 1800 \
    --output "$temporary_file" "$base_url/${files[$i]##*/}"
  if [[ "$(checksum "$temporary_file")" != "${checksums[$i]}" ]]; then
    echo "Checksum mismatch: $destination; existing file preserved." >&2
    exit 1
  fi
  mv -- "$temporary_file" "$destination"
  temporary_file=''
  echo "Downloaded and verified $destination"
done
