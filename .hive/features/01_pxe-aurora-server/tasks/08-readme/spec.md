# Task: 08-readme

## Feature: pxe-aurora-server

## Dependencies

_None_

## Goal

Documentação completa de uso, pré-requisitos, operação e troubleshooting

## Description

Criar README.md com: visão geral da arquitetura, pré-requisitos (podman, podman-compose, firewall), como buildar, como iniciar/parar, como verificar logs, como customizar (senha, usuário, range DHCP, interface), troubleshooting comum.

## Acceptance Criteria

- Diagrama ASCII da arquitetura
- Pré-requisitos listados (podman, podman-compose, portas firewall)
- Comandos build e start claros
- Como ver logs (podman logs -f)
- Como parar (podman-compose down)
- Seção de customização (variáveis editáveis)
- Troubleshooting: iPXE loop, DHCP conflict, SELinux, firewall

## Files

- README.md
