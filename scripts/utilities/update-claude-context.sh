#!/bin/bash
# Script para atualizar contexto do Claude automaticamente

echo "🔄 Atualizando contexto do Claude..."

# Executar context loader
if [ -f ".claude/context/context_loader.py" ]; then
    python3 .claude/context/context_loader.py generate
    echo "✅ Contexto atualizado"
else
    echo "❌ Context loader não encontrado"
    exit 1
fi

# Verificar se há mudanças
if [ -n "$(git status --porcelain .claude/context/current-context.md)" ]; then
    echo "📝 Contexto foi modificado"
    
    # Opcional: auto-commit das mudanças de contexto
    if [ "$1" == "--auto-commit" ]; then
        git add .claude/context/current-context.md
        git commit -m "chore: atualizar contexto do Claude [auto]"
        echo "💾 Contexto commitado automaticamente"
    fi
fi
