FROM alpine:3.20

# Install dependencies
RUN apk add --no-cache dnsmasq nginx curl

# Create directories
RUN mkdir -p /tftpboot /etc/nginx

# Download iPXE bootloaders
RUN curl -fsSL -o /tftpboot/undionly.kpxe https://boot.ipxe.org/undionly.kpxe \
    && curl -fsSL -o /tftpboot/ipxe.efi https://boot.ipxe.org/ipxe.efi

# Download Fedora 42 pxeboot assets
RUN curl -fsSL -o /tftpboot/vmlinuz \
    https://dl.fedoraproject.org/pub/fedora/linux/releases/42/Everything/x86_64/os/images/pxeboot/vmlinuz \
    && curl -fsSL -o /tftpboot/initrd.img \
    https://dl.fedoraproject.org/pub/fedora/linux/releases/42/Everything/x86_64/os/images/pxeboot/initrd.img

# Copy configuration files to their final locations
# (compose.yaml volumes override these at runtime for easy customization)
COPY config/dnsmasq.conf /etc/dnsmasq.conf
COPY config/nginx.conf /etc/nginx/nginx.conf

# Copy PXE menu and kickstart
COPY tftpboot/ /tftpboot/

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
