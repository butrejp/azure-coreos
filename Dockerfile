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

# 4. Install Azure Linux kernel (required for bootable OSTree deployments)
# Azure Linux uses a custom 6.18 LTS kernel with Hyper-V and Azure tuning
RUN dnf5 install -y --skip-unavailable kernel && \
    dnf5 clean all

# 5. Set up container-native OSTree filesystem layout
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

# 6. Mark image as bootable OSTree container
LABEL containers.bootc=1

CMD ["/bin/bash"]
