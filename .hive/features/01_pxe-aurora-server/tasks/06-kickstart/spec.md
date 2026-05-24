# Task: 06-kickstart

## Feature: pxe-aurora-server

## Dependencies

_None_

## Goal

Kickstart 100% automático que instala Aurora diretamente via ostreecontainer

## Description

Criar tftpboot/ks.cfg com instalação completamente automatizada: pt_BR, America/Sao_Paulo, teclado br-abnt2, clearpart total, particionamento GPT, ostreecontainer Aurora, usuário aurora no grupo wheel, reboot automático.

## Acceptance Criteria

- text mode (sem GUI no installer)
- keyboard --vckeymap=br-abnt2
- lang pt_BR.UTF-8
- timezone America/Sao_Paulo --utc
- network --bootproto=dhcp --device=link --activate
- clearpart --all --initlabel --disklabel=gpt
- reqpart --add-boot
- part / --grow --fstype=xfs
- ostreecontainer --url ghcr.io/ublue-os/aurora:latest --no-signature-verification
- rootpw --lock
- user --name=aurora --groups=wheel com senha temporária
- reboot --eject no final

## Files

- tftpboot/ks.cfg
