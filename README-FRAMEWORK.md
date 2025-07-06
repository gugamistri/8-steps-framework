# Framework de 8 Etapas - Guia de Início Rápido

Este projeto utiliza o **Framework de Implementação Sistemática de IA de 8 Etapas**, focado no desenvolvimento orientado pelo cliente.

## 🚀 Início Rápido

### 1. Verificar Status Atual
```bash
./scripts/automation/framework-automation.sh status
```

### 2. Executar Validação PRD
```bash
./scripts/automation/framework-automation.sh validate
```

### 3. Atualizar Contexto do Claude
```bash
./scripts/automation/framework-automation.sh update-context
```

### 4. Avançar para Próxima Etapa (quando pronto)
```bash
./scripts/automation/framework-automation.sh advance
```

## 📊 Dashboard de Progresso

Acompanhe o progresso em: [docs/framework/progress-tracker.md](docs/framework/progress-tracker.md)

## 📋 Etapas do Framework

1. **Stage 1**: Customer-Driven Problem Definition
2. **Stage 2**: Technical Architecture with Customer Context  
3. **Stage 3**: Customer Journey Mapping and Experience Design
4. **Stage 4**: Experience-Driven Design Systems
5. **Stage 5**: Collaborative Technical Design and Architecture
6. **Stage 6**: Engineering Quality Framework and Production Readiness
7. **Stage 7**: Collaborative Development and Technical Implementation
8. **Stage 8**: Production Deployment and AI System Operations

## 🔧 Comandos Úteis

### Validação e Status
- `python3 scripts/validation/prd_validator.py validate` - Validação completa
- `python3 scripts/validation/prd_validator.py status` - Status da etapa atual
- `python3 scripts/validation/prd_validator.py advance` - Avançar etapa

### Claude Code Integration
- `python3 .claude/context/context_loader.py generate` - Atualizar contexto
- `python3 .claude/context/context_loader.py prompt "sua pergunta"` - Prompt específico
- `./scripts/utilities/update-claude-context.sh` - Atualização automática

### Relatórios e Dashboard
- `./scripts/automation/framework-automation.sh report` - Gerar relatório
- `./scripts/automation/framework-automation.sh dashboard` - Atualizar dashboard

## 📁 Estrutura de Arquivos

```
.framework/          # Configurações do framework
├── config/         # Arquivos de configuração YAML
├── stages/         # Markers de conclusão de etapas
└── reports/        # Relatórios de validação

.claude/            # Integração Claude Code
├── context/        # Contextos específicos por etapa
└── prompts/        # Prompts pré-configurados

docs/               # Documentação
├── prd/           # Product Requirements Document
├── framework/     # Progresso do framework
└── reports/       # Relatórios gerados

scripts/            # Scripts de automação
├── validation/    # Validação PRD-Framework
├── automation/    # Automação de tarefas
└── utilities/     # Utilitários diversos
```

## 🎯 Próximos Passos

1. **Completar PRD**: Preencher `docs/prd/main-prd.md`
2. **Definir Personas**: Documentar `docs/prd/personas.md`
3. **Executar Discovery**: Começar Stage 1 do framework
4. **Validar Continuamente**: Usar validação automática

## 🆘 Troubleshooting

### Erro de Validação
```bash
# Ver detalhes do erro
python3 scripts/validation/prd_validator.py validate

# Verificar arquivos necessários
ls -la docs/prd/
```

### Contexto do Claude Desatualizado
```bash
# Forçar atualização
python3 .claude/context/context_loader.py generate
```

### Git Hooks Não Funcionando
```bash
# Reinstalar hooks
./scripts/automation/setup-git-hooks.sh
```

## 📞 Suporte

- Documentação completa: `docs/framework/`
- Relatórios de validação: `docs/reports/`
- Configuração: `.framework/config/`
