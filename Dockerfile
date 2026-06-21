FROM mcr.microsoft.com/azurelinux-beta/base/core:4.0
WORKDIR /workspace

# 1. Force-swap coreutils-single to full coreutils to prevent BlueBuild dependency conflicts
# Also install curl so we can download the external repository files
RUN dnf5 upgrade -y && \
    dnf5 install -y --allowerasing coreutils curl && \
    dnf5 clean all

# 2. Configure DNF5 to allow package cross-pollination from Fedora
RUN echo "allow_vendor_change=True" >> /etc/dnf/dnf.conf

# 3. Pull Fedora 44 official GPG keys and setup Fedora repositories
RUN curl -fsSL https://fedoraproject.org -o /etc/yum.repos.d/fedora.repo && \
    curl -fsSL https://fedoraproject.org -o /etc/yum.repos.d/fedora-updates.repo && \
    mkdir -p /etc/pki/rpm-gpg/ && \
    curl -fsSL https://fedoraproject.org -o /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-44-primary

# 4. Refresh package manager databases and install your required standard utilities
RUN dnf5 upgrade -y && \
    dnf5 install -y \
        gawk \
        sed \
        grep \
        tar \
        gzip \
        which \
        ca-certificates \
        util-linux && \
    dnf5 clean all

CMD ["/bin/bash"]
