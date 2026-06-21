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

# 3. Download Fedora GPG keys and fix repo files
RUN mkdir -p /etc/pki/rpm-gpg && \
    curl -o /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-43-x86_64 \
        https://download.fedoraproject.org/pub/fedora/linux/releases/43/Everything/x86_64/os/RPM-GPG-KEY-fedora-43-x86_64 && \
    curl -o /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-43-primary \
        https://getfedora.org/static/fedora.gpg && \
    for f in /etc/yum.repos.d/fedora*.repo; do \
        if [ -f "$f" ]; then \
            sed -i 's/$releasever/43/g' "$f" && \
            sed -i 's/^metalink/#metalink/g' "$f" && \
            sed -i 's|^#baseurl=http://download.example|baseurl=https://download.fedoraproject.org|g' "$f" && \
            sed -i 's|^baseurl=http://download.example|baseurl=https://download.fedoraproject.org|g' "$f"; \
        fi; \
    done && \
    sed -i 's/^enabled=1/enabled=0/g' /etc/yum.repos.d/fedora-cisco-openh264.repo && \
    sed -i 's/^enabled=1/enabled=0/g' /etc/yum.repos.d/fedora-modular.repo 2>/dev/null || true && \
    sed -i 's/^enabled=1/enabled=0/g' /etc/yum.repos.d/fedora-updates-modular.repo 2>/dev/null || true

# 4. Refresh metadata
RUN dnf5 makecache --refresh || echo "makecache failed but we persist"

# 5. Standard POSIX utilities
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
