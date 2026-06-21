FROM mcr.microsoft.com/azurelinux-beta/base/core:4.0

WORKDIR /workspace

# 1. Coreutils swap + allow mixing repos
RUN dnf5 upgrade -y && \
    dnf5 install -y --allowerasing coreutils && \
    echo "allow_vendor_change=True" >> /etc/dnf/dnf.conf && \
    dnf5 clean all

# 2. Install dnf-plugins and Fedora repo packages
RUN dnf5 install -y dnf5-plugins && \
    REPO_URL="https://download.fedoraproject.org/pub/fedora/linux/releases/43/Everything/x86_64/os/Packages/f" && \
    for pkg in fedora-repos fedora-release fedora-release-common; do \
        RPM=$(curl -sL "$REPO_URL/" | grep -oE "${pkg}-43-[^\"<>]+\\.noarch\\.rpm" | head -1) && \
        if [ -n "$RPM" ]; then \
            echo "Installing $RPM" && \
            dnf5 install -y --allowerasing "$REPO_URL/$RPM"; \
        else \
            echo "WARNING: Could not find $pkg, continuing anyway" && \
            exit 1; \
        fi; \
    done && \
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
