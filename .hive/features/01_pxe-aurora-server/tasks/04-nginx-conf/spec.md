# Task: 04-nginx-conf

## Feature: pxe-aurora-server

## Dependencies

_None_

## Goal

nginx HTTP server na porta 8080 para servir assets PXE (vmlinuz, initrd, ipxe scripts, kickstart)

## Description

Criar config/nginx.conf com HTTP server na porta 8080 servindo o diretório /tftpboot com autoindex habilitado e mime types corretos para servir binários PXE.

## Acceptance Criteria

- listen 8080
- root /tftpboot
- autoindex on
- mime types incluem application/octet-stream para binários
- sendfile on para performance

## Files

- config/nginx.conf
