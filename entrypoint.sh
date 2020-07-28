#!/bin/sh -l

set -e

info() {
  echo -e "\033[1;34m$1\033[0m"
}

warn() {
  echo "::warning :: $1"
}

error() {
  echo "::error :: $1"
  exit 1
}

source_file="${1}"
scene_names="${2}"
args="${3}"
manim_repo="${4}"
extra_packages="${5}"
extra_system_packages="${6}"
pre_compile="${7}"
post_compile="${8}"

if [[ -z "$source_file" ]]; then
  error "Input 'source_file' is missing."
fi

info "Downloading system packages for manim"
apt-get update && apt-get install -qqy --no-install-recommends \
  apt-utils \
  ffmpeg \
  sox \
  libcairo2-dev \
  texlive \
  texlive-fonts-extra \
  texlive-latex-extra \
  texlive-latex-recommended \
  texlive-science \
  tipa \
&& rm -rf /var/lib/apt/lists/*

info "Cloning $manim_repo ..."
git clone "$manim_repo" manim --depth=1
mv manim/* .

info "Installing requirements of manim..."
python -m pip install -r requirements.txt

if [[ -n "$extra_system_packages" ]]; then
  for pkg in $extra_system_packages; do
    info "Installing $pkg by apk..."
    apk --no-cache add "$pkg"
  done
fi

if [[ -n "$extra_packages" ]]; then
  for pkg in $extra_packages; do
    info "Installing $pkg by pip..."
    python -m pip install "$pkg"
  done
fi

if [[ -n "$pre_compile" ]]; then
  info "Run pre compile commands"
  eval "$pre_compile"
fi

info "Rendering..."
for pkg in $scene_names; do
  python manim.py "$source_file" "$pkg" "$args"
done
if [[ -n "$post_compile" ]]; then
  info "Run post compile commands"
  eval "$post_compile"
fi
