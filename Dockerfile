FROM mcr.microsoft.com/azurelinux-beta/base/core:4.0
WORKDIR /workspace
RUN dnf5 upgrade -y && \
    dnf5 install -y gawk sed grep tar gzip which ca-certificates util-linux && \
    dnf5 clean all
CMD ["/bin/bash"]
