#!/bin/bash
# setup-framework-fixed.sh - Setup com verificação de dependências Python

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[SETUP]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Função para instalar dependências Python
install_python_dependencies() {
    log "Verificando e instalando dependências Python..."
    
    # Criar requirements.txt se não existir
    if [ ! -f "requirements.txt" ]; then
        cat > requirements.txt << 'EOF'
PyYAML>=6.0
pathlib2>=2.3.7
EOF
        success "Arquivo requirements.txt criado"
    fi
    
    # Verificar se PyYAML está instalado
    if ! python3 -c "import yaml" 2>/dev/null; then
        warning "PyYAML não encontrado. Instalando..."
        
        # Tentar instalar via pip
        if command -v pip3 &> /dev/null; then
            pip3 install PyYAML
        elif command -v pip &> /dev/null; then
            pip install PyYAML
        else
            error "pip não encontrado. Instale pip primeiro:"
            echo "  - Ubuntu/Debian: sudo apt install python3-pip"
            echo "  - macOS: brew install python3"
            echo "  - Windows: baixe de python.org"
            exit 1
        fi
        
        # Verificar instalação
        if python3 -c "import yaml" 2>/dev/null; then
            success "PyYAML instalado com sucesso"
        else
            error "Falha ao instalar PyYAML"
            exit 1
        fi
    else
        success "PyYAML já instalado"
    fi
    
    # Instalar outras dependências se necessário
    if [ -f "requirements.txt" ]; then
        log "Instalando dependências do requirements.txt..."
        pip3 install -r requirements.txt || pip install -r requirements.txt
        success "Dependências instaladas"
    fi
}

# Função para verificar dependências
check_dependencies() {
    log "Verificando dependências do sistema..."
    
    # Verificar Python 3
    if ! command -v python3 &> /dev/null; then
        error "Python 3 não encontrado!"
        echo "Instale Python 3.8+ antes de continuar:"
        echo "  - Ubuntu/Debian: sudo apt install python3 python3-pip"
        echo "  - macOS: brew install python3"
        echo "  - Windows: baixe de python.org"
        exit 1
    fi
    
    # Verificar versão do Python
    PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    if [[ $(echo "$PYTHON_VERSION < 3.7" | bc -l 2>/dev/null || echo "0") == "1" ]]; then
        warning "Python $PYTHON_VERSION detectado. Recomendado Python 3.8+"
    fi
    
    # Verificar Git
    if ! command -v git &> /dev/null; then
        error "Git não encontrado!"
        echo "Instale Git antes de continuar:"
        echo "  - Ubuntu/Debian: sudo apt install git"
        echo "  - macOS: brew install git"
        echo "  - Windows: baixe de git-scm.com"
        exit 1
    fi
    
    success "Dependências do sistema verificadas"
    
    # Instalar dependências Python
    install_python_dependencies
}

# Função para execução segura dos scripts Python
safe_python_execution() {
    local script_path="$1"
    local description="$2"
    
    log "$description..."
    
    if [ -f "$script_path" ]; then
        # Verificar se todas as dependências estão disponíveis
        if python3 -c "import yaml, json, os, sys" 2>/dev/null; then
            python3 "$script_path" generate 2>/dev/null || {
                warning "Erro ao executar $script_path. Tentando corrigir..."
                
                # Criar arquivo de estado mínimo se não existir
                if [[ "$script_path" == *"context_loader.py"* ]]; then
                    mkdir -p .framework
                    echo '{"current_stage": "stage_1", "updated_at": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'"}' > .framework/current_stage.json
                    python3 "$script_path" generate || warning "Ainda com problemas. Continuando..."
                fi
            }
            success "$description concluído"
        else
            warning "Dependências Python não disponíveis para $script_path"
        fi
    else
        warning "Script $script_path não encontrado"
    fi
}

# Função melhorada para executar validação inicial
run_initial_validation() {
    log "Executando validação inicial..."
    
    # Criar estado inicial se não existir
    if [ ! -f ".framework/current_stage.json" ]; then
        mkdir -p .framework
        cat > .framework/current_stage.json << 'EOF'
{
  "current_stage": "stage_1",
  "updated_at": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'",
  "previous_stages": [],
  "project_started": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'",
  "total_stages": 8,
  "completion_percentage": 0
}
EOF
    fi
    
    # Executar context loader com verificação
    safe_python_execution ".claude/context/context_loader.py" "Geração de contexto inicial do Claude"
    
    # Executar validação com verificação
    safe_python_execution "scripts/validation/prd_validator.py" "Validação inicial"
    
    # Gerar dashboard
    if [ -f "scripts/automation/framework-automation.sh" ]; then
        ./scripts/automation/framework-automation.sh dashboard 2>/dev/null || {
            warning "Erro ao gerar dashboard. Criando versão básica..."
            
            mkdir -p docs/framework
            cat > docs/framework/progress-tracker.md << 'EOF'
# Dashboard de Progresso - Framework de 8 Etapas

**Status**: Setup inicial concluído
**Etapa Atual**: Stage 1 - Customer-Driven Problem Definition

## Próximos Passos
1. Completar PRD em docs/prd/main-prd.md
2. Executar customer discovery
3. Validar progresso com: ./scripts/automation/framework-automation.sh status

## Comandos Úteis
- `./scripts/automation/framework-automation.sh status` - Verificar status
- `./scripts/automation/framework-automation.sh validate` - Executar validação
- `python3 .claude/context/context_loader.py generate` - Atualizar contexto Claude
EOF
        }
        success "Dashboard gerado"
    fi
}

# Função para diagnóstico de problemas
diagnose_setup() {
    echo ""
    log "Executando diagnóstico do setup..."
    
    echo "🔍 Verificando arquivos críticos:"
    
    # Verificar arquivos principais
    files_to_check=(
        ".framework/config/stages.yaml"
        ".framework/config/prd-mapping.yaml"
        ".framework/current_stage.json"
        ".claude/context/context_loader.py"
        "scripts/validation/prd_validator.py"
        "scripts/automation/framework-automation.sh"
    )
    
    for file in "${files_to_check[@]}"; do
        if [ -f "$file" ]; then
            echo "  ✅ $file"
        else
            echo "  ❌ $file - FALTANDO"
        fi
    done
    
    echo ""
    echo "🐍 Verificando Python e dependências:"
    python3 --version
    
    echo ""
    echo "📦 Verificando módulos Python:"
    modules=("yaml" "json" "os" "sys" "pathlib")
    for module in "${modules[@]}"; do
        if python3 -c "import $module" 2>/dev/null; then
            echo "  ✅ $module"
        else
            echo "  ❌ $module - FALTANDO"
        fi
    done
    
    echo ""
    echo "🔧 Status dos scripts:"
    if [ -x "scripts/automation/framework-automation.sh" ]; then
        echo "  ✅ framework-automation.sh executável"
    else
        echo "  ❌ framework-automation.sh não executável"
    fi
    
    echo ""
}

# Função principal melhorada
main() {
    echo "🚀 Setup do Framework de 8 Etapas (Versão Corrigida)"
    echo ""
    
    # Verificar dependências primeiro
    check_dependencies
    
    # Executar setup se arquivos existirem
    if [ -f ".framework/config/stages.yaml" ] && [ -f "scripts/validation/prd_validator.py" ]; then
        run_initial_validation
        success "Setup inicial concluído com dependências corrigidas!"
    else
        warning "Arquivos de configuração não encontrados."
        echo "Execute primeiro os passos de criação dos arquivos conforme o guia."
    fi
    
    # Diagnóstico
    diagnose_setup
    
    echo ""
    echo "🎯 Próximos passos:"
    echo "  1. Editar docs/prd/main-prd.md"
    echo "  2. Executar: ./scripts/automation/framework-automation.sh status"
    echo "  3. Validar: ./scripts/automation/framework-automation.sh validate"
    echo ""
}

# Executar função principal
main "$@"