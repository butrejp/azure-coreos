FROM mcr.microsoft.com/azurelinux-beta/base/core:4.0
WORKDIR /workspace

# 1. Force-swap coreutils-single to full coreutils to prevent BlueBuild dependency conflicts
# 2. Install your required standard POSIX utilities
RUN dnf5 upgrade -y && \
    dnf5 install -y --allowerasing coreutils && \
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
