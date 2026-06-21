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
    curl -LO https://download.fedoraproject.org/pub/fedora/linux/releases/43/Everything/x86_64/os/Packages/f/fedora-gpg-keys-43-1.noarch.rpm && \
    rpm -Uvh --nodeps --force *.rpm && \
    dnf5 clean all

# 3. Fix Fedora repo files: replace $releasever with 43, disable metalink, set REAL baseurls, disable broken repos
RUN for f in /etc/yum.repos.d/fedora*.repo; do \
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

# 6. Install bootc and set up container-native layout
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
