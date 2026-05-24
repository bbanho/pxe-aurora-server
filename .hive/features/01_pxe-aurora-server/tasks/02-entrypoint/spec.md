# Task: 02-entrypoint

## Feature: pxe-aurora-server

## Dependencies

_None_

## Goal

Script de inicialização do container all-in-one com gestão correta de processos

## Description

Criar entrypoint.sh que inicia nginx em background e dnsmasq em foreground com tratamento correto de sinais SIGTERM/SIGINT para graceful shutdown.

## Acceptance Criteria

- entrypoint.sh existe e tem chmod +x
- nginx inicia em background
- dnsmasq inicia em foreground (mantém container vivo)
- trap SIGTERM/SIGINT para matar ambos os processos
- Exit code propagado corretamente

## Files

- entrypoint.sh
