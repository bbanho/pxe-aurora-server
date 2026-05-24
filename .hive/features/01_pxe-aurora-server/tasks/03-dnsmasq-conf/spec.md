# Task: 03-dnsmasq-conf

## Feature: pxe-aurora-server

## Dependencies

_None_

## Goal

Configuração dnsmasq com DHCP+TFTP+iPXE chainloading para BIOS e UEFI

## Description

Criar config/dnsmasq.conf com DHCP completo na rede 192.168.200.0/24, TFTP server, detecção de arquitetura BIOS/UEFI via DHCP Option 93, anti-loop iPXE via userclass, e chainload para HTTP.

## Acceptance Criteria

- interface=enp3s0 bind-dynamic
- dhcp-range=192.168.200.150,192.168.200.250,12h
- dhcp-option=3 gateway 192.168.200.1
- dhcp-option=6 DNS 192.168.200.1
- Tags BIOS (arch 0) e UEFI (arch 7,9) configuradas
- dhcp-userclass iPXE anti-loop
- BIOS->undionly.kpxe, UEFI->ipxe.efi, iPXE->http://192.168.200.115:8080/boot.ipxe
- enable-tftp tftp-root=/tftpboot

## Files

- config/dnsmasq.conf
