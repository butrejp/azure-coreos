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

# 3. Fix Fedora repo files: replace $releasever with 43, disable metalink, use direct baseurl, disable broken repos
RUN for f in /etc/yum.repos.d/fedora*.repo; do \
        if [ -f "$f" ]; then \
            sed -i 's/$releasever/43/g' "$f" && \
            sed -i 's/^metalink/#metalink/g' "$f" && \
            sed -i 's/^#baseurl/baseurl/g' "$f"; \
        fi; \
    done && \
    sed -i 's/^enabled=1/enabled=0/g' /etc/yum.repos.d/fedora-cisco-openh264.repo && \
    sed -i 's/^enabled=1/enabled=0/g' /etc/yum.repos.d/fedora-modular.repo 2>/dev/null || true && \
    sed -i 's/^enabled=1/enabled=0/g' /etc/yum.repos.d/fedora-updates-modular.repo 2>/dev/null || true && \
    cat /etc/yum.repos.d/fedora.repo 2>/dev/null || true

# 4. Refresh metadata (skip unavailable repos)
RUN dnf5 makecache --refresh --skip-unavailable || echo "makecache failed but we persist"

# 5. Standard POSIX utilities (skip unavailable repos)
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

CMD ["/bin/bash"]
