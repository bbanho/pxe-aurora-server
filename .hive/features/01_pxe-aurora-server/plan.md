# PXE Aurora Server — Container All-in-One

## Discovery

**Q: Qual variante do Aurora?**
A: `aurora` padrão (KDE Plasma, sem extras dev) — `ghcr.io/ublue-os/aurora:latest`

**Q: BIOS ou UEFI?**
A: Dual — BIOS (undionly.kpxe) + UEFI (ipxe.efi), tags condicionais no dnsmasq via DHCP Option 93

**Q: Tem DHCP existente na rede PXE?**
A: Não — o container faz DHCP completo (não Proxy DHCP)

**Q: Rede e IPs?**
A: Subnet 192.168.200.0/24, host em 192.168.200.115, interface enp3s0, gateway 192.168.200.1

**Q: Acesso à internet durante instalação?**
A: Sim — gateway 192.168.200.1 tem internet (necessário para pull da OCI image do ghcr.io)

**Q: Nível de automação?**
A: 100% automático — Kickstart apaga disco, instala Aurora OCI, cria usuário, reboot

**Q: Arquitetura do container?**
A: All-in-one (container único) com dnsmasq + nginx, gerenciado por podman-compose

**Research:**
- Aurora é distribuída como OCI image `ghcr.io/ublue-os/aurora:latest` (Fedora Kinoite base)
- Fedora 42 fornece vmlinuz + initrd.img para PXE em `https://dl.fedoraproject.org/pub/fedora/linux/releases/42/Everything/x86_64/os/images/pxeboot/`
- Kickstart usa `ostreecontainer --url ghcr.io/ublue-os/aurora:latest --no-signature-verification` para instalar Aurora diretamente
- dnsmasq: DHCP completo + TFTP, host networking obrigatório + NET_ADMIN
- iPXE: TFTP entrega bootloader → iPXE carrega boot.ipxe via HTTP → Anaconda com ks.cfg
- Pitfall crítico: iPXE boot loop resolvido com `dhcp-userclass=set:ipxe,iPXE`
- SELinux: volumes com `:z` flag para auto-labeling

## Non-Goals

- Sem suporte a múltiplas distros (somente Aurora)
- Sem cache local da OCI image (pull direto do ghcr.io)
- Sem interface web de gerenciamento
- Sem suporte a WiFi ou outras interfaces
- Sem configuração pós-instalação além do kickstart básico
- Sem multi-architecture (x86_64 apenas)

## Ghost Diffs (Alternativas Rejeitadas)

- **Dois containers separados (dnsmasq + nginx)**: Rejeitado em favor de all-in-one por simplicidade operacional
- **Podman Quadlet (systemd units)**: Rejeitado por curva de aprendizado; pode ser adicionado depois
- **Proxy DHCP**: Rejeitado porque não há DHCP existente na rede cabeada
- **iVentoy**: Rejeitado — mais pesado, menos controlável, menos educativo
- **bootc install ephemeral**: Rejeitado — requer live OS pré-existente no cliente

## Architecture

```
Cliente PXE (BIOS ou UEFI)
        │
        │ 1. DHCP request (broadcast, porta 67)
        ▼
┌─────────────────────────────────────────────┐
│  Container pxe-server (Alpine Linux)        │
│  network_mode: host | cap_add: NET_ADMIN    │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │ dnsmasq                             │   │
│  │  • DHCP: .150-.250, gw .1, dns .1   │   │
│  │  • TFTP: /tftpboot/                 │   │
│  │  • BIOS → undionly.kpxe (TFTP)      │   │
│  │  • UEFI → ipxe.efi (TFTP)          │   │
│  │  • iPXE → boot.ipxe (HTTP :8080)   │   │
│  └─────────────────────────────────────┘   │
│  ┌─────────────────────────────────────┐   │
│  │ nginx :8080                         │   │
│  │  • /tftpboot/boot.ipxe              │   │
│  │  • /tftpboot/vmlinuz                │   │
│  │  • /tftpboot/initrd.img             │   │
│  │  • /tftpboot/ks.cfg                 │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
        │ 2. TFTP → bootloader iPXE
        │ 3. HTTP → boot.ipxe menu
        │ 4. HTTP → vmlinuz + initrd (Anaconda F42)
        │ 5. Anaconda lê ks.cfg via HTTP
        │ 6. ostreecontainer pull ghcr.io/ublue-os/aurora:latest
        │ 7. Instalação completa → reboot → Aurora!
        ▼
   Aurora instalado ✓
```

## File Structure

```
pxe/
├── Containerfile         # Alpine + dnsmasq + nginx + assets baixados na build
├── compose.yaml          # podman-compose: host net, NET_ADMIN, volumes
├── entrypoint.sh         # nginx bg + dnsmasq fg + trap SIGTERM
├── config/
│   ├── dnsmasq.conf      # DHCP+TFTP config
│   └── nginx.conf        # HTTP :8080
└── tftpboot/
    ├── boot.ipxe         # Menu iPXE
    └── ks.cfg            # Kickstart Aurora
```

## Tasks

### Task 1: Containerfile
Criar `Containerfile` Alpine-based que:
- Instala: dnsmasq, nginx, curl
- Baixa na build: undionly.kpxe e ipxe.efi de boot.ipxe.org
- Baixa na build: vmlinuz e initrd.img do Fedora 42 pxeboot
- Copia configs e tftpboot para locais corretos
- ENTRYPOINT: /entrypoint.sh

### Task 2: entrypoint.sh
Script de inicialização:
- trap SIGTERM/SIGINT para graceful shutdown
- nginx -g 'daemon off;' em background
- dnsmasq --no-daemon em foreground
- Propaga exit codes corretamente

### Task 3: config/dnsmasq.conf
- interface=enp3s0, bind-dynamic
- dhcp-range=192.168.200.150,192.168.200.250,12h
- dhcp-option=3,192.168.200.1 (gateway)
- dhcp-option=6,192.168.200.1 (DNS)
- dhcp-match tags BIOS (arch 0) e UEFI (arch 7, 9)
- dhcp-userclass iPXE detection (anti-loop)
- dhcp-boot: BIOS→undionly.kpxe, UEFI→ipxe.efi, iPXE→http://192.168.200.115:8080/boot.ipxe
- enable-tftp, tftp-root=/tftpboot

### Task 4: config/nginx.conf
- listen 8080
- root /tftpboot
- autoindex on
- mime types corretos

### Task 5: tftpboot/boot.ipxe
- Menu iPXE com opção "Instalar Aurora Linux"
- kernel http://192.168.200.115:8080/vmlinuz com args Anaconda
- initrd http://192.168.200.115:8080/initrd.img
- inst.ks=http://192.168.200.115:8080/ks.cfg
- inst.repo apontando para Fedora 42 mirror

### Task 6: tftpboot/ks.cfg
- text mode
- keyboard br-abnt2, lang pt_BR.UTF-8, timezone America/Sao_Paulo
- network --bootproto=dhcp --activate
- clearpart --all --initlabel --disklabel=gpt
- reqpart --add-boot
- part / --grow --fstype=xfs
- ostreecontainer --url ghcr.io/ublue-os/aurora:latest --no-signature-verification
- rootpw --lock
- user --name=aurora --groups=wheel --password (temporária)
- reboot

### Task 7: compose.yaml
- service: pxe-server
- build: context .
- network_mode: host
- cap_add: [NET_ADMIN]
- volumes: ./config/dnsmasq.conf, ./config/nginx.conf, ./tftpboot
- restart: unless-stopped

### Task 8: README.md
- Pré-requisitos (podman, podman-compose)
- Como buildar e iniciar
- Como verificar logs
- Como parar
- Como customizar (senha, usuário, range DHCP)
- Troubleshooting comum
