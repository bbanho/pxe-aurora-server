#!/bin/bash
echo "Iniciando o Servidor PXE Aurora..."
sudo podman-compose up -d
echo "Servidor online! Acompanhe os logs com: sudo podman logs -f pxe_pxe-server_1"
