#!/bin/bash
# scripts/automation/framework-automation.sh

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
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

# Função para verificar dependências
check_dependencies() {
    log "Verificando dependências..."
    
    # Verifica Python
    if ! command -v python3 &> /dev/null; then
        error "Python3 não encontrado!"
        exit 1
    fi
    
    # Verifica estrutura do projeto
    if [ ! -d ".framework" ]; then
        error "Estrutura do framework não encontrada! Execute primeiro o setup."
        exit 1
    fi
    
    success "Dependências verificadas"
}

# Função para atualizar contexto do Claude
update_claude_context() {
    log "Atualizando contexto do Claude..."
    
    if [ -f ".claude/context/context_loader.py" ]; then
        python3 .claude/context/context_loader.py generate
        success "Contexto do Claude atualizado"
    else
        warning "Script de contexto não encontrado"
    fi
}

# Função para executar validação PRD
run_prd_validation() {
    log "Executando validação PRD..."
    
    if [ -f "scripts/validation/prd_validator.py" ]; then
        python3 scripts/validation/prd_validator.py validate
        
        # Captura o código de saída
        if [ $? -eq 0 ]; then
            success "Validação PRD concluída"
        else
            warning "Validação PRD encontrou problemas"
        fi
    else
        error "Script de validação não encontrado"
        return 1
    fi
}

# Função para verificar status da etapa atual
check_stage_status() {
    log "Verificando status da etapa atual..."
    
    if [ -f "scripts/validation/prd_validator.py" ]; then
        python3 scripts/validation/prd_validator.py status
    else
        error "Script de validação não encontrado"
    fi
}

# Função para avançar para próxima etapa
advance_stage() {
    log "Tentando avançar para próxima etapa..."
    
    if [ -f "scripts/validation/prd_validator.py" ]; then
        python3 scripts/validation/prd_validator.py advance
        
        if [ $? -eq 0 ]; then
            success "Avançado para próxima etapa"
            update_claude_context
        else
            warning "Não foi possível avançar. Verifique os requisitos da etapa atual."
        fi
    else
        error "Script de validação não encontrado"
    fi
}

# Função para gerar relatório de progresso
generate_progress_report() {
    log "Gerando relatório de progresso..."
    
    # Executar validação e capturar output
    python3 scripts/validation/prd_validator.py validate
    
    # Atualizar dashboard de progresso
    update_progress_dashboard
    
    success "Relatório de progresso gerado"
}

# Função para atualizar dashboard de progresso
update_progress_dashboard() {
    local dashboard_file="docs/framework/progress-tracker.md"
    local current_stage=$(python3 -c "
import json
from pathlib import Path
try:
    with open('.framework/current_stage.json', 'r') as f:
        print(json.load(f)['current_stage'])
except:
    print('stage_1')
")
    
    log "Atualizando dashboard de progresso..."
    
    cat > "$dashboard_file" << EOF
# Dashboard de Progresso - Framework de 8 Etapas

**Última Atualização**: $(date +'%Y-%m-%d %H:%M:%S')

## Status Geral
- **Etapa Atual**: $current_stage
- **Data de Início**: $(date +'%Y-%m-%d')

## Progresso por Etapa

### ✅ Etapas Completadas
$(python3 -c "
import json
from pathlib import Path
try:
    with open('.framework/current_stage.json', 'r') as f:
        data = json.load(f)
        completed = data.get('previous_stages', [])
        for stage in completed:
            print(f'- {stage}')
except:
    print('- Nenhuma etapa completada ainda')
")

### 🔄 Etapa Atual
- **Etapa**: $current_stage
- **Status**: Em andamento

### ⏳ Próximas Etapas
$(python3 -c "
stages = ['stage_1', 'stage_2', 'stage_3', 'stage_4', 'stage_5', 'stage_6', 'stage_7', 'stage_8']
current = '$current_stage'
try:
    current_index = stages.index(current)
    remaining = stages[current_index + 1:]
    for stage in remaining:
        print(f'- {stage}')
except:
    print('- Erro ao determinar próximas etapas')
")

## Links Rápidos
- [Último Relatório de Validação](../reports/)
- [Configuração do Framework](../../.framework/config/)
- [Contexto do Claude](../../.claude/context/current-context.md)

## Comandos Úteis
\`\`\`bash
# Verificar status atual
./scripts/automation/framework-automation.sh status

# Executar validação
./scripts/automation/framework-automation.sh validate

# Atualizar contexto do Claude
./scripts/automation/framework-automation.sh update-context

# Avançar etapa (se validação passar)
./scripts/automation/framework-automation.sh advance
\`\`\`
EOF

    success "Dashboard atualizado: $dashboard_file"
}

# Função para setup inicial
setup_project() {
    log "Executando setup inicial do projeto..."
    
    # Criar estrutura se não existir
    mkdir -p .framework/{config,templates,stages,reports}
    mkdir -p .claude/{context,prompts,stage-configs}
    mkdir -p docs/{prd,framework,progress,reports}
    mkdir -p scripts/{validation,automation}
    
    # Criar arquivo de estado inicial se não existir
    if [ ! -f ".framework/current_stage.json" ]; then
        cat > .framework/current_stage.json << EOF
{
  "current_stage": "stage_1",
  "updated_at": "$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)",
  "previous_stages": []
}
EOF
    fi
    
    # Criar arquivo PRD básico se não existir
    if [ ! -f "docs/prd/main-prd.md" ]; then
        cat > docs/prd/main-prd.md << EOF
# Product Requirements Document (PRD)

## Problema do Cliente
[Defina o problema que será resolvido]

## Objetivos
[Liste os objetivos principais do produto]

## Stakeholders
[Identifique os principais stakeholders]

## Requisitos Funcionais
[Liste os requisitos funcionais]

## Requisitos Técnicos
[Liste os requisitos técnicos]

## Métricas de Sucesso
[Defina como o sucesso será medido]

## Cronograma
[Defina marcos e cronograma]
EOF
    fi
    
    update_progress_dashboard
    success "Setup inicial concluído"
}

# Função para mostrar ajuda
show_help() {
    echo "Framework de 8 Etapas - Scripts de Automação"
    echo ""
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos disponíveis:"
    echo "  setup           - Setup inicial do projeto"
    echo "  status          - Verificar status da etapa atual"
    echo "  validate        - Executar validação PRD"
    echo "  update-context  - Atualizar contexto do Claude"
    echo "  advance         - Avançar para próxima etapa"
    echo "  report          - Gerar relatório de progresso"
    echo "  dashboard       - Atualizar dashboard de progresso"
    echo "  help            - Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 setup"
    echo "  $0 validate"
    echo "  $0 advance"
}

# Função principal
main() {
    case "${1:-help}" in
        "setup")
            setup_project
            ;;
        "status")
            check_dependencies
            check_stage_status
            ;;
        "validate")
            check_dependencies
            run_prd_validation
            ;;
        "update-context")
            check_dependencies
            update_claude_context
            ;;
        "advance")
            check_dependencies
            advance_stage
            ;;
        "report")
            check_dependencies
            generate_progress_report
            ;;
        "dashboard")
            check_dependencies
            update_progress_dashboard
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            error "Comando desconhecido: $1"
            show_help
            exit 1
            ;;
    esac
}

# Executar função principal com todos os argumentos
main "$@"