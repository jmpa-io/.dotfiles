# A clean Arch Linux environment to test these dotfiles in (see run-tests.sh).
# Build:  docker build -t dotfiles-arch-test -f test/arch/Dockerfile test/arch
FROM archlinux:latest

# base tools + a non-root user: makepkg (AUR builds) refuses to run as root.
RUN pacman -Syu --noconfirm --needed base-devel git sudo make shellcheck xorg-server-xvfb xorg-xdpyinfo imagemagick \
 && useradd -m -G wheel tester \
 && echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel \
 && rm -rf /var/cache/pacman/pkg/*

USER tester
WORKDIR /home/tester
