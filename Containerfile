FROM alpine:3.20

# Install dependencies
RUN apk add --no-cache dnsmasq nginx curl

# Create directories
RUN mkdir -p /tftpboot /config

# Download iPXE bootloaders
RUN curl -fsSL -o /tftpboot/undionly.kpxe https://boot.ipxe.org/undionly.kpxe \
    && curl -fsSL -o /tftpboot/ipxe.efi https://boot.ipxe.org/ipxe.efi

# Download Fedora 42 pxeboot assets
RUN curl -fsSL -o /tftpboot/vmlinuz \
    https://dl.fedoraproject.org/pub/fedora/linux/releases/42/Everything/x86_64/os/images/pxeboot/vmlinuz \
    && curl -fsSL -o /tftpboot/initrd.img \
    https://dl.fedoraproject.org/pub/fedora/linux/releases/42/Everything/x86_64/os/images/pxeboot/initrd.img

# Copy configuration files (created in subsequent tasks)
COPY config/dnsmasq.conf /config/dnsmasq.conf
COPY config/nginx.conf /config/nginx.conf

# Copy PXE menu and kickstart
COPY tftpboot/ /tftpboot/

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
