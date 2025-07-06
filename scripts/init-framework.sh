#!/bin/bash
echo "🚀 Inicializando Framework de 8 Etapas..."
echo "📍 Verificando estrutura de diretórios..."
if [ -d ".framework" ]; then
    echo "✅ Estrutura encontrada"
else
    echo "❌ Execute primeiro o setup de diretórios"
    exit 1
fi
echo "🎯 Framework pronto para uso!"
