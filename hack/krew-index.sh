#!/bin/bash

set -euo pipefail
set -x

VERSION=$(git describe --tags --abbrev=0 | cut -c2-)
KREW_INDEX_PATH="${HOME}/src/krew-index"
FILE="${KREW_INDEX_PATH}/plugins/score.yaml"

checksum() {
    grep -E "kube-score_${VERSION}_${1}_amd64.tar.gz" dist/checksums.txt | awk '{print $1}'
}

gg() {
    git -C "$KREW_INDEX_PATH" "$@"
}

gg fetch origin
gg reset --hard origin/master
gg checkout -b "kube-score-${VERSION}"

yq write --inplace "$FILE" "spec.version" "v${VERSION}"

yq write --inplace "$FILE" "spec.platforms[0].uri" "https://github.com/zegl/kube-score/releases/download/v${VERSION}/kube-score_${VERSION}_darwin_amd64.tar.gz"
yq write --inplace "$FILE" "spec.platforms[0].sha256" "$(checksum darwin)"

yq write --inplace "$FILE" "spec.platforms[1].uri" "https://github.com/zegl/kube-score/releases/download/v${VERSION}/kube-score_${VERSION}_linux_amd64.tar.gz"
yq write --inplace "$FILE" "spec.platforms[1].sha256" "$(checksum linux)"

gg add plugins/score.yaml
gg commit -m "Update score to v${VERSION}"
gg push -u zegl "kube-score-${VERSION}"

open "https://github.com/kubernetes-sigs/krew-index/compare/master...zegl:kube-score-${VERSION}?expand=1"
