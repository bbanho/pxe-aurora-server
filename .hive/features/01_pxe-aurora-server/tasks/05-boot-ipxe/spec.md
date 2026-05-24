# Task: 05-boot-ipxe

## Feature: pxe-aurora-server

## Dependencies

_None_

## Goal

Menu iPXE que carrega Anaconda do Fedora 42 com kickstart Aurora apontando para o HTTP server

## Description

Criar tftpboot/boot.ipxe com menu iPXE apresentando opção de instalar Aurora. Kernel e initrd carregados via HTTP (192.168.200.115:8080). Args Anaconda: inst.ks, inst.repo, ip=dhcp, quiet.

## Acceptance Criteria

- #!ipxe header presente
- menu com item 'Instalar Aurora Linux'
- kernel via HTTP 192.168.200.115:8080/vmlinuz
- initrd via HTTP 192.168.200.115:8080/initrd.img
- inst.ks=http://192.168.200.115:8080/ks.cfg
- inst.repo aponta para Fedora 42 mirror
- ip=dhcp nos args do kernel
- Timeout no menu (30s) com default auto-install

## Files

- tftpboot/boot.ipxe
