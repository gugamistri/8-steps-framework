#!/bin/bash
# scripts/automation/setup-git-hooks.sh

# Script para configurar git hooks para validação automática

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[Git Hooks Setup]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log "Configurando Git Hooks para validação automática..."

# 1. Pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Pre-commit hook para validação PRD-Framework

echo "🔍 Executando validação pre-commit..."

# Verificar se há mudanças em arquivos críticos
CRITICAL_FILES=$(git diff --cached --name-only | grep -E "(docs/prd/|src/|\.py$|\.md$)" || true)

if [ -n "$CRITICAL_FILES" ]; then
    echo "📝 Arquivos críticos modificados, executando validação..."
    
    # Executar validação PRD
    if [ -f "scripts/validation/prd_validator.py" ]; then
        python3 scripts/validation/prd_validator.py status
        VALIDATION_RESULT=$?
        
        if [ $VALIDATION_RESULT -ne 0 ]; then
            echo "❌ Validação PRD falhou. Execute 'python3 scripts/validation/prd_validator.py validate' para detalhes."
            echo "💡 Use 'git commit --no-verify' para pular validação (não recomendado)"
            exit 1
        fi
    fi
    
    # Atualizar contexto do Claude
    if [ -f ".claude/context/context_loader.py" ]; then
        python3 .claude/context/context_loader.py generate
        git add .claude/context/current-context.md 2>/dev/null || true
    fi
fi

echo "✅ Validação pre-commit aprovada"
exit 0
EOF

# 2. Pre-push hook
cat > .git/hooks/pre-push << 'EOF'
#!/bin/bash
# Pre-push hook para validação abrangente

echo "🚀 Executando validação pre-push..."

# Executar validação completa
if [ -f "scripts/validation/prd_validator.py" ]; then
    echo "📊 Executando validação completa..."
    python3 scripts/validation/prd_validator.py validate
    
    if [ $? -ne 0 ]; then
        echo "❌ Validação completa falhou. Não é possível fazer push."
        echo "💡 Resolva os problemas antes de tentar novamente."
        exit 1
    fi
fi

# Verificar se documentação está atualizada
if [ -f "scripts/automation/framework-automation.sh" ]; then
    echo "📈 Atualizando dashboard de progresso..."
    ./scripts/automation/framework-automation.sh dashboard
    
    # Adicionar arquivos atualizados ao commit se houver mudanças
    if [ -n "$(git status --porcelain docs/framework/progress-tracker.md)" ]; then
        echo "📝 Dashboard atualizado, incluindo no commit..."
        git add docs/framework/progress-tracker.md
        git commit -m "chore: atualizar dashboard de progresso [skip ci]" || true
    fi
fi

echo "✅ Validação pre-push aprovada"
exit 0
EOF

# 3. Post-commit hook
cat > .git/hooks/post-commit << 'EOF'
#!/bin/bash
# Post-commit hook para atualizações automáticas

echo "📝 Executando tarefas post-commit..."

# Atualizar contexto do Claude após commit
if [ -f ".claude/context/context_loader.py" ]; then
    python3 .claude/context/context_loader.py generate > /dev/null 2>&1 || true
fi

# Verificar se critérios da etapa foram atendidos
if [ -f "scripts/validation/prd_validator.py" ]; then
    # Verificação silenciosa do status
    STAGE_STATUS=$(python3 scripts/validation/prd_validator.py status 2>/dev/null | grep -o "✅ OK\|❌ PENDENTE" || echo "❓ DESCONHECIDO")
    echo "📊 Status da etapa atual: $STAGE_STATUS"
    
    # Se tudo OK, sugerir avanço
    if [[ "$STAGE_STATUS" == "✅ OK" ]]; then
        echo ""
        echo "🎉 Todos os critérios da etapa atual foram atendidos!"
        echo "💡 Considere avançar para a próxima etapa: ./scripts/automation/framework-automation.sh advance"
        echo ""
    fi
fi

exit 0
EOF

# 4. Commit-msg hook para padrões de mensagem
cat > .git/hooks/commit-msg << 'EOF'
#!/bin/bash
# Commit-msg hook para padronização de mensagens

COMMIT_MSG_FILE=$1
COMMIT_MSG=$(cat $COMMIT_MSG_FILE)

# Verificar se a mensagem segue padrões básicos
if [[ ${#COMMIT_MSG} -lt 10 ]]; then
    echo "❌ Mensagem de commit muito curta (mínimo 10 caracteres)"
    echo "💡 Use mensagens descritivas como: 'feat: implementar validação de usuário'"
    exit 1
fi

# Sugerir prefixos se não estiver usando conventional commits
if [[ ! $COMMIT_MSG =~ ^(feat|fix|docs|style|refactor|test|chore|perf)(\(.+\))?: ]]; then
    echo "💡 Considere usar Conventional Commits:"
    echo "   feat: nova funcionalidade"
    echo "   fix: correção de bug"
    echo "   docs: atualização de documentação"
    echo "   refactor: refatoração de código"
    echo "   test: adição de testes"
    echo "   chore: tarefas de manutenção"
fi

# Adicionar referência da etapa atual se não existir
CURRENT_STAGE=$(python3 -c "
import json
try:
    with open('.framework/current_stage.json', 'r') as f:
        stage = json.load(f)['current_stage']
        print(f'[{stage}]')
except:
    print('')
" 2>/dev/null || echo "")

if [[ -n "$CURRENT_STAGE" && ! $COMMIT_MSG =~ \[stage_ ]]; then
    # Adicionar referência da etapa no final da mensagem
    echo "" >> $COMMIT_MSG_FILE
    echo "" >> $COMMIT_MSG_FILE
    echo "Etapa: $CURRENT_STAGE" >> $COMMIT_MSG_FILE
fi

exit 0
EOF

# 5. Script para instalar hooks opcionais
cat > scripts/automation/install-optional-hooks.sh << 'EOF'
#!/bin/bash
# Instalar hooks opcionais adicionais

echo "🔧 Instalando hooks opcionais..."

# Hook para verificar se arquivos grandes estão sendo commitados
cat > .git/hooks/pre-commit-file-size << 'EOL'
#!/bin/bash
# Verificar tamanho de arquivos

MAX_SIZE=5242880 # 5MB
large_files=$(git diff --cached --name-only | xargs ls -la 2>/dev/null | awk -v max=$MAX_SIZE '$5 > max {print $9 " (" $5 " bytes)"}')

if [ -n "$large_files" ]; then
    echo "❌ Arquivos muito grandes detectados:"
    echo "$large_files"
    echo "💡 Considere usar Git LFS ou reduzir o tamanho dos arquivos"
    exit 1
fi
EOL

# Hook para verificar segredos/secrets
cat > .git/hooks/pre-commit-secrets << 'EOL'
#!/bin/bash
# Verificar se há secrets no código

SECRETS_PATTERNS=(
    "password\s*=\s*['\"].*['\"]"
    "api_key\s*=\s*['\"].*['\"]"
    "secret\s*=\s*['\"].*['\"]"
    "token\s*=\s*['\"].*['\"]"
    "private_key"
)

for pattern in "${SECRETS_PATTERNS[@]}"; do
    if git diff --cached | grep -iE "$pattern"; then
        echo "❌ Possível secret detectado no código!"
        echo "🔒 Verifique se não há informações sensíveis sendo commitadas"
        exit 1
    fi
done
EOL

chmod +x .git/hooks/pre-commit-file-size
chmod +x .git/hooks/pre-commit-secrets

echo "✅ Hooks opcionais instalados"
echo "Para usar, adicione as chamadas no pre-commit principal"
EOF

# Tornar todos os hooks executáveis
chmod +x .git/hooks/pre-commit
chmod +x .git/hooks/pre-push
chmod +x .git/hooks/post-commit
chmod +x .git/hooks/commit-msg
chmod +x scripts/automation/install-optional-hooks.sh

success "Git hooks configurados com sucesso!"

echo ""
echo "🎯 Hooks configurados:"
echo "  ✅ pre-commit  - Validação PRD e atualização de contexto"
echo "  ✅ pre-push    - Validação completa e atualização de dashboard"
echo "  ✅ post-commit - Atualizações automáticas e sugestões"
echo "  ✅ commit-msg  - Padronização de mensagens"
echo ""
echo "💡 Para pular validação em casos específicos:"
echo "   git commit --no-verify"
echo "   git push --no-verify"
echo ""
echo "🔧 Para instalar hooks opcionais:"
echo "   ./scripts/automation/install-optional-hooks.sh"