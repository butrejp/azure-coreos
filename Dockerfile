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

# 3. Fix Fedora repo files: replace $releasever with 43, disable metalink, use direct baseurl
RUN for f in /etc/yum.repos.d/fedora*.repo; do \
        if [ -f "$f" ]; then \
            sed -i 's/$releasever/43/g' "$f" && \
            sed -i 's/^metalink/#metalink/g' "$f" && \
            sed -i 's/^#baseurl/baseurl/g' "$f"; \
        fi; \
    done && \
    cat /etc/yum.repos.d/fedora.repo 2>/dev/null || true

# 4. Refresh metadata (may explode, that's fine)
RUN dnf5 makecache --refresh || echo "makecache failed but we persist"

# 5. Standard POSIX utilities (will now pull from the cursed repo mix)
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
