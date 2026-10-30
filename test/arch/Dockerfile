# A clean Arch Linux environment to test these dotfiles in (see run-tests.sh).
# Build:  docker build -t dotfiles-arch-test -f test/arch/Dockerfile test/arch
# Arch is rolling, so the base tracks 'latest' by default (the tests exist to catch breakage on
# current Arch). For a reproducible build pin it: --build-arg BASE_IMAGE=archlinux@sha256:<digest>
ARG BASE_IMAGE=archlinux:latest
FROM ${BASE_IMAGE}

# base tools + a non-root user: makepkg (AUR builds) refuses to run as root. The passwordless
# sudo is for the test run only (pacman, /etc installs); this image is not meant to be shipped.
RUN pacman -Syu --noconfirm --needed base-devel git sudo make shellcheck xorg-server-xvfb xorg-xdpyinfo imagemagick \
 && useradd -m -G wheel tester \
 && echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel \
 && chmod 0440 /etc/sudoers.d/wheel \
 && rm -rf /var/cache/pacman/pkg/*

USER tester
WORKDIR /home/tester
