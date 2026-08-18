#!/bin/bash

# Verifica se o comando nvidia-smi funciona na máquina host
if command -v nvidia-smi &> /dev/null && nvidia-smi &> /dev/null; then
    echo "🟢 GPU NVIDIA detectada! Subindo contêiner com suporte a GPU..."
    docker compose -f docker-compose.yaml -f docker-compose.nvidia.yaml up -d
else
    echo "🟡 GPU NVIDIA não detectada. Subindo contêiner em modo CPU/Integrada..."
    docker compose up -d
fi