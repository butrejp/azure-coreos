FROM mcr.microsoft.com/azurelinux-beta/base/core:4.0

WORKDIR /workspace

# 1. Coreutils swap + allow mixing repos
RUN dnf5 upgrade -y && \
    dnf5 install -y --allowerasing coreutils && \
    echo "allow_vendor_change=True" >> /etc/dnf/dnf.conf && \
    dnf5 clean all

# 2. Install curl, download Fedora RPMs, force-install them with rpm
RUN dnf5 install -y curl && \
    mkdir -p /tmp/fedora-rpms && cd /tmp/fedora-rpms && \
    curl -LO https://download.fedoraproject.org/pub/fedora/linux/releases/43/Everything/x86_64/os/Packages/f/fedora-repos-43-1.noarch.rpm && \
    curl -LO https://download.fedoraproject.org/pub/fedora/linux/releases/43/Everything/x86_64/os/Packages/f/fedora-release-43-25.noarch.rpm && \
    curl -LO https://download.fedoraproject.org/pub/fedora/linux/releases/43/Everything/x86_64/os/Packages/f/fedora-release-common-43-25.noarch.rpm && \
    rpm -Uvh --nodeps --force *.rpm && \
    dnf5 clean all

# 3. Refresh metadata (may explode, that's fine)
RUN dnf5 makecache --refresh || echo "makecache failed but we persist"

# 4. Standard POSIX utilities (will now pull from the cursed repo mix)
RUN dnf5 install -y \
        gawk \
        sed \
        grep \
        tar \
        gzip \
        which \
        ca-certificates \
        util-linux \
    && dnf5 clean all

CMD ["/bin/bash"]
