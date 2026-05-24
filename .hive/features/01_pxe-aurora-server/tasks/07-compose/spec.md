# Task: 07-compose

## Feature: pxe-aurora-server

## Dependencies

_None_

## Goal

podman-compose para orquestrar o container PXE all-in-one com host networking e NET_ADMIN

## Description

Criar compose.yaml com serviço pxe-server: build do Containerfile local, network_mode host, cap_add NET_ADMIN, volumes para configs e tftpboot, restart unless-stopped.

## Acceptance Criteria

- service pxe-server definido
- build: context: .
- network_mode: host
- cap_add: [NET_ADMIN]
- volume ./config/dnsmasq.conf:/etc/dnsmasq.conf:ro,z
- volume ./config/nginx.conf:/etc/nginx/nginx.conf:ro,z
- volume ./tftpboot:/tftpboot:ro,z
- restart: unless-stopped
- sem ports: (desnecessário com host network)

## Files

- compose.yaml
