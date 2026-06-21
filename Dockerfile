FROM mcr.microsoft.com/azurelinux-beta/base/core:4.0

WORKDIR /workspace

# 1. Coreutils swap + allow mixing repos
RUN dnf5 upgrade -y && \
    dnf5 install -y --allowerasing coreutils && \
    echo "allow_vendor_change=True" >> /etc/dnf/dnf.conf && \
    dnf5 clean all

# 2. Standard POSIX utilities
RUN dnf5 install -y --skip-unavailable \
        gawk \
        sed \
        grep \
        tar \
        gzip \
        which \
        ca-certificates \
        util-linux \
    && dnf5 clean all

# 3. Install bootc, rpm-ostree, and ostree tooling
RUN dnf5 install -y --skip-unavailable bootc rpm-ostree ostree && \
    dnf5 clean all

# 4. Install Azure Linux kernel
RUN dnf5 install -y --skip-unavailable kernel && \
    dnf5 clean all

# 5. Fix RPM database for OSTree compatibility
# rpm-ostree expects the rpmdb at /usr/share/rpm, not /var/lib/rpm
RUN mkdir -p /usr/share/rpm && \
    if [ -d /var/lib/rpm ] && [ "$(ls -A /var/lib/rpm)" ]; then \
        cp -a /var/lib/rpm/* /usr/share/rpm/ 2>/dev/null || true; \
    fi && \
    rpm --rebuilddb && \
    # Ensure /usr/share/rpm is actually populated
    test -f /usr/share/rpm/Packages || test -f /usr/share/rpm/rpmdb.sqlite || \
    test -f /usr/share/rpm/rpmdb.sqlite-shm || \
    (echo "RPM db not found at /usr/share/rpm" && exit 1)

# 6. Set up container-native OSTree filesystem layout
RUN mkdir -p /run/ostree && \
    ln -sf / /sysroot && \
    mkdir -p /usr/lib/ostree && \
    echo '{"sysroot":{"readonly":false}}' > /usr/lib/ostree/prepare-root.cfg && \
    touch /run/ostree-booted && \
    mkdir -p /ostree/repo && \
    ostree init --repo=/ostree/repo --mode=bare-user && \
    mkdir -p /ostree/deploy && \
    rm -rf /var && mkdir -p /var && \
    test -f /usr/lib/os-release || ln -sf /etc/os-release /usr/lib/os-release

# 7. Mark image as bootable OSTree container
LABEL containers.bootc=1

# 8. Set up container-native OSTree filesystem layout
RUN mkdir -p /run/ostree && \
    ln -sf / /sysroot && \
    mkdir -p /usr/lib/ostree && \
    echo '{"sysroot":{"readonly":false}}' > /usr/lib/ostree/prepare-root.cfg && \
    touch /usr/lib/ostree-booted && \
    touch /run/ostree-booted && \
    mkdir -p /ostree/repo && \
    ostree init --repo=/ostree/repo --mode=bare-user && \
    mkdir -p /ostree/deploy && \
    rm -rf /var && mkdir -p /var && \
    test -f /usr/lib/os-release || ln -sf /etc/os-release /usr/lib/os-release

CMD ["/bin/bash"]
