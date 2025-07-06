#!/usr/bin/env python3
# .claude/context/context_loader.py

import json
import yaml
from pathlib import Path
from datetime import datetime

class ClaudeContextLoader:
    def __init__(self):
        self.framework_config = self.load_config()
        self.current_stage = self.get_current_stage()
        
    def load_config(self):
        """Carrega configuração do framework"""
        config_path = Path(".framework/config/stages.yaml")
        if config_path.exists():
            with open(config_path, 'r') as f:
                return yaml.safe_load(f)
        return {}
    
    def get_current_stage(self):
        """Obtém a etapa atual"""
        state_file = Path(".framework/current_stage.json")
        if state_file.exists():
            with open(state_file, 'r') as f:
                return json.load(f).get('current_stage', 'stage_1')
        return 'stage_1'
    
    def load_prd_content(self):
        """Carrega conteúdo relevante do PRD"""
        prd_content = {}
        
        # Problema principal
        problem_file = Path("docs/prd/problem-statement.md")
        if problem_file.exists():
            prd_content['problem_statement'] = problem_file.read_text()
        
        # Personas
        personas_file = Path("docs/prd/personas.md")
        if personas_file.exists():
            prd_content['target_audience'] = personas_file.read_text()
        
        # Métricas de sucesso
        metrics_file = Path("docs/prd/success-metrics.md")
        if metrics_file.exists():
            prd_content['success_metrics'] = metrics_file.read_text()
        
        # Requisitos técnicos
        tech_file = Path("docs/prd/technical-requirements.md")
        if tech_file.exists():
            prd_content['technical_requirements'] = tech_file.read_text()
        
        return prd_content
    
    def get_stage_info(self):
        """Obtém informações da etapa atual"""
        stages = self.framework_config.get('stages', {})
        stage_info = stages.get(self.current_stage, {})
        
        return {
            'name': stage_info.get('name', self.current_stage),
            'description': stage_info.get('description', ''),
            'deliverables': stage_info.get('key_deliverables', []),
            'validation_criteria': stage_info.get('validation_criteria', []),
            'duration': stage_info.get('duration_weeks', 'N/A')
        }
    
    def get_recent_validation_report(self):
        """Obtém o relatório de validação mais recente"""
        reports_dir = Path("docs/reports")
        if not reports_dir.exists():
            return None
        
        # Encontra o relatório mais recente
        report_files = list(reports_dir.glob("validation-*.md"))
        if not report_files:
            return None
        
        latest_report = max(report_files, key=lambda x: x.stat().st_mtime)
        return latest_report.read_text()
    
    def generate_context(self):
        """Gera contexto completo para o Claude"""
        stage_info = self.get_stage_info()
        prd_content = self.load_prd_content()
        validation_report = self.get_recent_validation_report()
        
        # Template base
        template_path = Path(".claude/context/base-context.md")
        if template_path.exists():
            context_template = template_path.read_text()
        else:
            context_template = self.get_default_template()
        
        # Substituições
        replacements = {
            '${CURRENT_STAGE_NAME}': stage_info['name'],
            '${CURRENT_STAGE_DESCRIPTION}': stage_info['description'],
            '${CURRENT_STAGE_DELIVERABLES}': '\n'.join([f"- {d}" for d in stage_info['deliverables']]),
            '${CURRENT_STAGE_VALIDATION_CRITERIA}': '\n'.join([f"- {c}" for c in stage_info['validation_criteria']]),
            '${PRD_PROBLEM_STATEMENT}': prd_content.get('problem_statement', 'Não definido'),
            '${PRD_TARGET_AUDIENCE}': prd_content.get('target_audience', 'Não definido'),
            '${PRD_SUCCESS_METRICS}': prd_content.get('success_metrics', 'Não definido'),
            '${PRD_TECHNICAL_REQUIREMENTS}': prd_content.get('technical_requirements', 'Não definido'),
            '${RECOMMENDED_NEXT_ACTIONS}': self.get_next_actions()
        }
        
        context = context_template
        for placeholder, value in replacements.items():
            context = context.replace(placeholder, value)
        
        # Adiciona relatório de validação se disponível
        if validation_report:
            context += f"\n\n## Último Relatório de Validação\n\n{validation_report}"
        
        return context
    
    def get_next_actions(self):
        """Gera lista de próximas ações"""
        stage_specific_actions = {
            'stage_1': [
                "Completar entrevistas com clientes",
                "Documentar declaração do problema no PRD",
                "Quantificar impacto do problema",
                "Estabelecer board consultivo de clientes"
            ],
            'stage_2': [
                "Mapear features para tecnologias baseado nas necessidades do cliente",
                "Planejar arquitetura empresarial e integração com sistemas legados",
                "Integrar requisitos de segurança e compliance",
                "Planejar performance e escalabilidade"
            ],
            'stage_3': [
                "Analisar jornada do cliente B2B multi-stakeholder",
                "Realizar validação e teste da experiência do cliente",
                "Desenvolver user stories com integração de feedback",
                "Estabelecer padrões de acessibilidade e usabilidade"
            ],
            'stage_4': [
                "Desenvolver sistema de design validado pelo cliente",
                "Criar padrões de interação com IA",
                "Otimizar experiência de todos os stakeholders",
                "Estabelecer consistência e escalabilidade do design"
            ],
            'stage_5': [
                "Estabelecer colaboração técnica entre engenharia e produto",
                "Documentar Architecture Decision Records (ADRs)",
                "Realizar avaliação de viabilidade técnica",
                "Integrar requisitos não funcionais"
            ],
            'stage_6': [
                "Implementar processos de revisão de código e qualidade",
                "Desenvolver estratégias de teste com validação do cliente",
                "Configurar pipelines CI/CD e automação de deploy",
                "Estabelecer monitoramento e observabilidade"
            ],
            'stage_7': [
                "Executar desenvolvimento orientado por engenharia com IA",
                "Integrar validação do cliente durante desenvolvimento",
                "Implementar protocolos de spikes técnicos",
                "Gerenciar velocidade e capacidade da engenharia"
            ],
            'stage_8': [
                "Implementar pipelines MLOps e deploy de modelos",
                "Configurar monitoramento em produção",
                "Acompanhar e otimizar experiência do cliente",
                "Implementar tratamento de erros e recuperação"
            ]
        }
        
        actions = stage_specific_actions.get(self.current_stage, ["Definir próximas ações"])
        return '\n'.join([f"- {action}" for action in actions])
    
    def get_default_template(self):
        """Template padrão caso o arquivo não exista"""
        return """
# Contexto do Framework - ${CURRENT_STAGE_NAME}

## Etapa Atual
**Nome**: ${CURRENT_STAGE_NAME}
**Descrição**: ${CURRENT_STAGE_DESCRIPTION}

## Objetivos
${CURRENT_STAGE_DELIVERABLES}

## Critérios de Validação
${CURRENT_STAGE_VALIDATION_CRITERIA}

## Requisitos PRD
**Problema**: ${PRD_PROBLEM_STATEMENT}
**Stakeholders**: ${PRD_TARGET_AUDIENCE}
**Métricas**: ${PRD_SUCCESS_METRICS}

## Próximas Ações
${RECOMMENDED_NEXT_ACTIONS}
"""
    
    def save_context_file(self):
        """Salva contexto atual em arquivo"""
        context = self.generate_context()
        
        # Salva contexto atual
        context_file = Path(".claude/context/current-context.md")
        context_file.parent.mkdir(parents=True, exist_ok=True)
        
        with open(context_file, 'w', encoding='utf-8') as f:
            f.write(context)
        
        print(f"📝 Contexto atualizado: {context_file}")
        return context_file
    
    def get_stage_specific_prompt(self, user_question):
        """Gera prompt específico da etapa com a pergunta do usuário"""
        stage_info = self.get_stage_info()
        
        prompt = f"""
CONTEXTO: Framework de 8 Etapas - {stage_info['name']}

ETAPA ATUAL: {stage_info['description']}

FOCO DA ETAPA:
{chr(10).join([f"- {d}" for d in stage_info['deliverables']])}

CRITÉRIOS DE VALIDAÇÃO:
{chr(10).join([f"- {c}" for c in stage_info['validation_criteria']])}

PERGUNTA/TAREFA:
{user_question}

INSTRUÇÕES:
1. Analise a pergunta no contexto da etapa atual
2. Verifique alinhamento com os objetivos da etapa
3. Considere os critérios de validação
4. Sugira próximos passos se aplicável
5. Identifique possíveis riscos ou gaps

RESPOSTA:
"""
        return prompt

def main():
    """Função principal para uso via linha de comando"""
    import sys
    
    loader = ClaudeContextLoader()
    
    if len(sys.argv) > 1:
        command = sys.argv[1]
        
        if command == "generate":
            context_file = loader.save_context_file()
            print(f"Contexto gerado: {context_file}")
            
        elif command == "prompt" and len(sys.argv) > 2:
            user_question = " ".join(sys.argv[2:])
            prompt = loader.get_stage_specific_prompt(user_question)
            print(prompt)
            
        elif command == "context":
            print(loader.generate_context())
            
        else:
            print("Comandos: generate, prompt <pergunta>, context")
    else:
        loader.save_context_file()

if __name__ == "__main__":
    main()