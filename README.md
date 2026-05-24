# PXE Aurora Server

Servidor PXE all-in-one para instalação automatizada do [Aurora Linux](https://getaurora.dev/) (base Fedora Kinoite) via rede, utilizando **dnsmasq** (DHCP + TFTP) e **nginx** (HTTP) em um único container Alpine.

## Arquitetura

```
┌─────────────────────────────────────────────────────────────────┐
│                        Rede Física                              │
│                   192.168.200.0/24                               │
│                                                                  │
│  ┌──────────────┐      ┌─────────────────────────────────────┐  │
│  │   Cliente     │      │  Servidor PXE (host 192.168.200.115) │  │
│  │   PXE         │      │                                       │  │
│  │  (BIOS/UEFI)  │      │  ┌──────────────┐  ┌──────────────┐  │  │
│  │              │      │  │   dnsmasq     │  │    nginx      │  │  │
│  │  1. DHCP     │──────│  │  • DHCP       │  │  • HTTP :8080 │  │  │
│  │   request    │      │  │  • TFTP        │  │  • boot.ipxe  │  │  │
│  │              │      │  │  • undionly    │  │  • vmlinuz    │  │  │
│  │  2. TFTP     │◄─────│  │    .kpxe(BIOS) │  │  • initrd.img │  │  │
│  │   bootloader │      │  │  • shimx64.efi │  │  • ks.cfg     │  │  │
│  │              │      │  │    (UEFI)      │  └──────────────┘  │  │
│  │  3. HTTP     │◄─────│  └──────────────┘                       │  │
│  │   menu iPXE  │      │                                         │  │
│  │              │      └─────────────────────────────────────────┘  │
│  │  4. HTTP     │                  │                                │
│  │   vmlinuz +  │                  │ 5. ostreecontainer pull        │
│  │   initrd     │                  ▼                                │
│  └──────────────┘        ┌────────────────────┐                    │
│                          │ ghcr.io/ublue-os/   │                    │
│                          │ aurora:latest       │                    │
│                          └────────────────────┘                    │
└─────────────────────────────────────────────────────────────────┘
```

### Fluxo de Boot

1. **DHCP Discovery** — Cliente envia broadcast DHCP; dnsmasq responde com IP, gateway e servidor TFTP
2. **TFTP Bootloader** — Arquitetura detectada via DHCP Option 93:
   - BIOS → `undionly.kpxe`
   - UEFI → `shimx64.efi`
3. **iPXE → HTTP** — iPXE carrega `boot.ipxe` via HTTP em `:8080`, exibindo menu interativo
4. **Anaconda** — vmlinuz + initrd.img (Fedora 42) baixados via HTTP; instalação lê `ks.cfg`
5. **Aurora** — Kickstart executa `ostreecontainer --url ghcr.io/ublue-os/aurora:latest` e instala o sistema

## Pré-requisitos

### 1. Podman

```bash
# Fedora / RHEL
sudo dnf install podman

# Ubuntu / Debian
sudo apt install podman

# Verificar versão
podman --version   # >= 4.0 recomendado
```

### 2. Podman-compose

```bash
# Instalação via pip
pip install podman-compose

# Ou via pacote do sistema (Fedora)
sudo dnf install podman-compose

# Verificar
podman-compose --version
```

### 3. Portas de Firewall

O servidor utiliza **host networking** — as portas abaixo devem estar liberadas no firewall do host:

| Porta    | Protocolo | Serviço   | Finalidade          |
|----------|-----------|-----------|---------------------|
| `67/udp` | DHCP      | dnsmasq   | Atribuição de IPs   |
| `69/udp` | TFTP      | dnsmasq   | Transferência do bootloader |
| `4011/udp` | PXE     | dnsmasq   | Proxy DHCP (se habilitado) |
| `8080/tcp` | HTTP    | nginx     | Menu iPXE, kernel, initrd, ks.cfg |

Exemplo com `firewalld`:

```bash
sudo firewall-cmd --add-port=67/udp --add-port=69/udp --add-port=8080/tcp
sudo firewall-cmd --runtime-to-permanent
```

Exemplo com `iptables`:

```bash
sudo iptables -A INPUT -p udp --dport 67 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 69 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
```

### 4. SELinux

Se SELinux está **enforcing** (padrão no Fedora), os volumes já utilizam a flag `:z` para auto-labeling. Nenhuma ação adicional é necessária.

## Quick Start

### 1. Build da imagem

```bash
podman-compose build
```

Isso baixa na build:
- `/tftpboot/undionly.kpxe` e `/tftpboot/shimx64.efi` (bootloaders iPXE)
- `/tftpboot/vmlinuz` e `/tftpboot/initrd.img` (Fedora 42 pxeboot)

### 2. Iniciar o servidor

```bash
podman-compose up -d
```

O container será iniciado em modo daemon e reiniciará automaticamente se cair (`restart: unless-stopped`).

### 3. Verificar logs

```bash
podman logs -f pxe-server
```

Ou via podman-compose:

```bash
podman-compose logs -f
```

### 4. Parar o servidor

```bash
podman-compose down
```

Remove o container (a imagem permanece em cache para reinício rápido).

## Customização

Edite os arquivos de configuração e recrie o container.

### Interface de rede (`config/dnsmasq.conf`)

```ini
interface=enp3s0
```

Altere para o nome da interface de rede do servidor PXE (ex: `eth0`, `ens18`).

### Range DHCP (`config/dnsmasq.conf`)

```ini
dhcp-range=192.168.200.150,192.168.200.250,12h
```

Ajuste o range de IPs e lease time conforme sua rede.

### Gateway e DNS (`config/dnsmasq.conf`)

```ini
dhcp-option=3,192.168.200.1
dhcp-option=6,192.168.200.1
```

- `option 3`: gateway padrão
- `option 6`: servidor DNS

### IP do servidor HTTP (`config/dnsmasq.conf` e `tftpboot/boot.ipxe`)

```bash
# config/dnsmasq.conf — linha 26
dhcp-boot=tag:ipxe,http://SEU_IP_AQUI:8080/boot.ipxe

# tftpboot/boot.ipxe — linha 11
kernel http://SEU_IP_AQUI:8080/vmlinuz ...
```

> **Importante:** O servidor utiliza `network_mode: host`, portanto o IP deve ser o IP real do host na rede.

### Senha e usuário do sistema instalado (`tftpboot/ks.cfg`)

```ini
user --name=aurora --groups=wheel --password=SUA_SENHA
```

> **Atenção:** Esta senha é temporária. O primeiro boot do Aurora Linux exige definição de nova senha.

### Arquivos de configuração

```
pxe/
├── Containerfile               # Imagem Alpine + dependências + assets
├── compose.yaml                # Orquestração podman-compose
├── entrypoint.sh               # Entrypoint com graceful shutdown
├── config/
│   ├── dnsmasq.conf            # DHCP + TFTP
│   └── nginx.conf              # HTTP :8080
└── tftpboot/
    ├── boot.ipxe               # Menu PXE
    ├── ks.cfg                  # Kickstart Aurora
    ├── undionly.kpxe           # Bootloader BIOS (iPXE)
    ├── shimx64.efi                # Bootloader UEFI (iPXE shim)
    ├── vmlinuz                 # Kernel Fedora 42
    └── initrd.img              # Initramfs Fedora 42
```

Após alterar qualquer arquivo, reconstrua e reinicie:

```bash
podman-compose build && podman-compose up -d
```

## Estrutura de Arquivos

```
pxe/
├── Containerfile              # Alpine + dnsmasq + nginx + assets
├── compose.yaml               # podman-compose: host net, NET_ADMIN, volumes
├── entrypoint.sh              # nginx bg + dnsmasq fg + traps
├── README.md                  # Esta documentação
├── config/
│   ├── dnsmasq.conf           # DHCP range, TFTP, boot files
│   └── nginx.conf             # Servidor HTTP :8080
├── tftpboot/
│   ├── boot.ipxe              # Menu iPXE
│   ├── ks.cfg                 # Kickstart Aurora Linux
│   ├── undionly.kpxe          # Bootloader BIOS
│       ├── shimx64.efi               # Bootloader UEFI
│   ├── vmlinuz                # Kernel Fedora 42
│   └── initrd.img             # Initramfs Fedora 42
└── test_*.sh                  # Testes de validação
```

## Troubleshooting

### iPXE loop (cliente reinicia ciclicamente)

**Sintoma:** O cliente PXE baixa o bootloader, carrega o menu iPXE, mas volta ao início do ciclo infinitamente.

**Causa mais comum:** O dnsmasq está servindo o bootloader iPXE novamente após o cliente já estar rodando iPXE — o cliente pede DHCP de novo e recebe `undionly.kpxe`/`shimx64.efi` em vez do próximo estágio HTTP.

**Solução:** A configuração já inclui detecção anti-loop via `dhcp-userclass`:

```ini
dhcp-userclass=set:ipxe,iPXE
dhcp-boot=tag:ipxe,http://192.168.200.115:8080/boot.ipxe
```

O iPXE se identifica com a userclass `iPXE`, e o dnsmasq roteia para o boot HTTP em vez de re-entregar o bootloader TFTP.

**Verificação:**

```bash
# Confirme que a regra anti-loop está presente
grep -E 'dhcp-userclass|dhcp-boot=tag:ipxe' config/dnsmasq.conf
```

### Conflito com DHCP existente na rede

**Sintoma:** Cliente recebe IP de outro servidor DHCP, ou IP inesperado.

**Causa:** Outro servidor DHCP (roteador, outro PXE) está ativo na mesma rede.

**Solução:**
1. Identifique o DHCP conflitante: `sudo tcpdump -i enp3s0 port 67 or port 68`
2. Desative o DHCP do roteador na porta cabeada
3. Ou mude o range DHCP em `config/dnsmasq.conf` para evitar colisão

> **Nota:** Este container faz **DHCP completo** (não Proxy DHCP). Ele deve ser o único servidor DHCP na rede.

### SELinux bloqueando acesso aos volumes

**Sintoma:** Container não inicia, ou nginx/dnsmasq não conseguem ler arquivos montados.

**Log:** `ausearch -m avc -ts recent`

**Solução:**

As montagens no `compose.yaml` já incluem `:z` para auto-labeling SELinux:

```yaml
volumes:
  - ./config/dnsmasq.conf:/etc/dnsmasq.conf:ro,z
  - ./config/nginx.conf:/etc/nginx/nginx.conf:ro,z
  - ./tftpboot:/tftpboot:ro,z
```

Se o problema persistir, verifique o contexto SELinux:

```bash
ls -Z config/dnsmasq.conf
# Deve mostrar: system_u:object_r:container_file_t:s0
```

Se não estiver correto:

```bash
restorecon -Rv config/ tftpboot/
```

### Firewall bloqueando DHCP/TFTP/HTTP

**Sintoma:** Cliente não consegue fazer DHCP discovery, ou bootloader não carrega, ou menu HTTP não aparece.

**Verificação rápida:**

```bash
# Teste se a porta 8080 está acessível
curl -s http://localhost:8080/boot.ipxe

# Verifique portas abertas
sudo ss -tulpn | grep -E ':(67|69|8080)'
```

**Solução:**

Libere as portas conforme seção [Portas de Firewall](#3-portas-de-firewall).

Se estiver usando `firewalld`:

```bash
sudo firewall-cmd --list-ports
```

### Container não inicia

**Sintoma:** `podman-compose up -d` falha ou container cai imediatamente.

**Diagnóstico:**

```bash
# Logs completos
podman-compose logs

# Verifique se o container existe e seu status
podman ps -a

# Teste de sintaxe do entrypoint
bash -n entrypoint.sh

# Teste de sintaxe do dnsmasq (se instalado no host)
dnsmasq --test -C config/dnsmasq.conf
```

**Causas comuns:**
- Porta 67 já em uso por outro serviço DHCP (NetworkManager, outro dnsmasq)
- Interface de rede incorreta em `config/dnsmasq.conf` (`interface=enp3s0`)
- SELinux bloqueando (veja seção acima)

### Instalação falha no cliente

**Sintoma:** Anaconda inicia mas não encontra o repositório ou a imagem OCI.

**Verificação:**

```bash
# Teste se o mirror Fedora está acessível do container
podman exec pxe-server curl -s -o /dev/null -w "%{http_code}" \
  https://dl.fedoraproject.org/pub/fedora/linux/releases/42/Everything/x86_64/os/

# Teste se a OCI image Aurora existe
podman exec pxe-server curl -s -o /dev/null -w "%{http_code}" \
  https://ghcr.io/v2/ublue-os/aurora/manifests/latest
```

**Soluções:**
- Verifique se o gateway (`192.168.200.1`) tem acesso à internet
- Confirme que DNS está funcionando (`dhcp-option=6`)
- A instalação requer internet para pull da OCI image do ghcr.io

### Bootloader não encontrado (TFTP timeout)

**Sintoma:** Cliente PXE recebe IP mas trava em "TFTP timeout" ou "File not found".

**Verificação:**

```bash
# Confira se os bootloaders foram baixados na build
ls -la tftpboot/undionly.kpxe tftpboot/shimx64.efi

# Verifique permissões
ls -la tftpboot/
```

**Solução:** Reconstrua a imagem para baixar novamente os assets:

```bash
podman-compose build --no-cache && podman-compose up -d
```
