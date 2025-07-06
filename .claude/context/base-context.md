# .claude/context/base-context.md

# Contexto do Framework de 8 Etapas

Você está trabalhando em um projeto que segue o **Framework de Implementação Sistemática de IA de 8 Etapas**, focado no desenvolvimento orientado pelo cliente.

## Etapa Atual: ${CURRENT_STAGE_NAME}

### Descrição da Etapa
${CURRENT_STAGE_DESCRIPTION}

### Objetivos Principais
${CURRENT_STAGE_DELIVERABLES}

### Critérios de Validação
${CURRENT_STAGE_VALIDATION_CRITERIA}

## Requisitos PRD Relevantes

### Problema do Cliente
${PRD_PROBLEM_STATEMENT}

### Stakeholders-Alvo
${PRD_TARGET_AUDIENCE}

### Métricas de Sucesso
${PRD_SUCCESS_METRICS}

### Requisitos Técnicos
${PRD_TECHNICAL_REQUIREMENTS}

## Instruções de Trabalho

### Foco da Etapa Atual
- Mantenha sempre o foco nos requisitos do PRD
- Valide cada decisão contra os critérios da etapa atual
- Considere o impacto nos stakeholders identificados
- Documente decisões e rationale

### Validações Obrigatórias
- [ ] Alinhamento com problema do cliente definido no PRD
- [ ] Atendimento aos critérios de validação da etapa
- [ ] Consideração dos requisitos técnicos
- [ ] Impacto positivo nas métricas de sucesso

### Próximos Passos
${RECOMMENDED_NEXT_ACTIONS}

## Arquivos Relevantes

### Documentação PRD
- `docs/prd/main-prd.md` - PRD principal
- `docs/prd/problem-statement.md` - Definição do problema
- `docs/prd/personas.md` - Personas e stakeholders

### Progresso do Framework
- `docs/framework/progress-tracker.md` - Acompanhamento do progresso
- `.framework/current_stage.json` - Estado atual do projeto

### Relatórios de Validação
- `docs/reports/` - Relatórios de validação mais recentes

---

**IMPORTANTE**: Sempre execute `python scripts/validation/prd_validator.py validate` antes de fazer alterações significativas para verificar alinhamento com PRD e framework.