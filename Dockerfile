FROM mcr.microsoft.com/azurelinux-beta/base/core:4.0

WORKDIR /workspace

# Import Fedora 43 key/repo
RUN echo "allow_vendor_change=True" >> /etc/dnf/dnf.conf && \
    rpm --import https://src.fedoraproject.org/rpms/fedora-repos/raw/rawhide/f/RPM-GPG-KEY-fedora-43-primary

COPY fedora43.repo /etc/yum.repos.d/fedora43.repo

# 1. Core system setup + bootc/CoreOS-style packages
RUN dnf5 upgrade -y && \
    dnf5 install -y --allowerasing --skip-unavailable \
        bootupd \
        grub2-efi-x64 \
        shim \
        audit \
        bash \
        bootc \
        ca-certificates \
        chrony \
        cloud-init \
        coreutils \
        curl \
        dbus-broker \
        dhcp-client \
        dnf5 \
        dnf5-plugins \
        dracut-config-generic \
        dracut-config-rescue \
        dracut-network \
        e2fsprogs \
        filesystem \
        firewalld \
        fwupd \
        gawk \
        glibc \
        grep \
        gzip \
        hostname \
        initial-setup \
        initscripts \
        iproute \
        iputils \
        kbd \
        kernel \
        kernel-core \
        kernel-modules \
        kernel-modules-extra \
        kernel-tools \
        less \
        man-db \
        ncurses \
        NetworkManager \
        openssh-clients \
        openssh-server \
        parted \
        plymouth \
        policycoreutils \
        prefixdevname \
        procps-ng \
        rng-tools \
        rootfiles \
        rpm \
        rsync \
        sed \
        selinux-policy-targeted \
        setup \
        shadow-utils \
        sssd-common \
        sssd-kcm \
        sudo \
        systemd \
        systemd-resolved \
        tar \
        util-linux \
        vim-minimal \
        which \
        zram-generator-defaults \
    && systemctl enable sshd NetworkManager firewalld chronyd cloud-init cloud-init-local 2>/dev/null || true

# 2. Re-stage EFI paths so bootupd can adopt them, then bake metadata
RUN mkdir -p /usr/lib/bootupd/updates/efi && \
    if [ -d /boot/efi/EFI/fedora ]; then \
        cp /boot/efi/EFI/fedora/* /usr/lib/bootupd/updates/efi/ 2>/dev/null || true; \
    elif [ -d /boot/efi/EFI/azurelinux ]; then \
        cp /boot/efi/EFI/azurelinux/* /usr/lib/bootupd/updates/efi/ 2>/dev/null || true; \
    else \
        find /boot -name "*.efi" -exec cp {} /usr/lib/bootupd/updates/efi/ \; 2>/dev/null || true; \
    fi && \
    bootupctl backend generate-update-metadata

# 3. OSTree/bootc filesystem layout
RUN rm -rf /home /root && \
    ln -s var/home /home && \
    ln -s var/roothome /root && \
    mkdir -p /sysroot && \
    ln -s sysroot/ostree /ostree && \
    mkdir -p /usr/lib/ostree && \
    printf '[composefs]\nenabled = true\n' > /usr/lib/ostree/prepare-root.conf && \
    \
    # Modern dnf5 relocates DB directly to /usr/lib/sysimage/rpm.
    mkdir -p /usr/lib/sysimage/rpm && \
    if [ -d /var/lib/rpm ] && [ ! -L /var/lib/rpm ]; then \
        cp -a /var/lib/rpm/. /usr/lib/sysimage/rpm/ 2>/dev/null || true; \
    fi && \
    rm -rf /var/lib/rpm && \
    ln -s ../../usr/lib/sysimage/rpm /var/lib/rpm && \
    \
    # Ensure /var/mail compliance
    rm -rf /var/mail && \
    ln -s spool/mail /var/mail && \
    \
    # Pure clean state for runtime systemd-tmpfiles initialization
    # DO NOT drop /usr/lib/bootupd/updates during your purge
    rm -rf /var/lib/alternatives/* && \
    find /var -type f -delete 2>/dev/null || true && \
    find /var -type d -empty -delete 2>/dev/null || true && \
    rm -rf /run/* /tmp/* && \
    # Clear out /boot now that bootupctl has finished indexing everything
    find /boot -mindepth 1 -delete 2>/dev/null || true && \
    mkdir -p /boot /run /tmp /var/cache /var/log /var/tmp \
             /var/spool /var/lib/alternatives /var/db /var/adm


# 4. Create default core user with systemd sysusers.d entry
RUN useradd -m -G wheel -s /bin/bash core && \
    echo "core ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/core && \
    chmod 440 /etc/sudoers.d/core && \
    passwd -d core || true && \
    printf 'u core 1000:1000 "Core User" /var/home/core /bin/bash\n' > /usr/lib/sysusers.d/core.conf

# 5. Clean up dnf cache layers post-configuration
RUN dnf5 clean all && rm -rf /var/{cache,log,lib/dnf5}/* /tmp/* /root/.cache

# 6. Validate bootc structural integrity
RUN bootc container lint

# 7. Mark as bootable OSTree/bootc image
LABEL ostree.bootable=1
LABEL containers.bootc=1

# 8. Systemd as entrypoint
STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]