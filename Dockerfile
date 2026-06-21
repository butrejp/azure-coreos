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

# 3. Install bootc and set up container-native layout
RUN dnf5 install -y --skip-unavailable bootc rpm-ostree && \
    mkdir -p /run/ostree && \
    ln -sf / /sysroot && \
    # bootc expects this for container builds
    mkdir -p /usr/lib/ostree && \
    echo '{"sysroot":{"readonly":false}}' > /usr/lib/ostree/prepare-root.cfg && \
    # Create the booted marker for rpm-ostree
    touch /run/ostree-booted && \
    dnf5 clean all

CMD ["/bin/bash"]
