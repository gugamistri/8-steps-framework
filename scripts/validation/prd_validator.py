#!/usr/bin/env python3
# scripts/validation/prd_validator.py

import yaml
import json
import os
from datetime import datetime
from pathlib import Path

class PRDFrameworkValidator:
    def __init__(self):
        self.config_path = Path(".framework/config")
        self.stages_config = self.load_yaml("stages.yaml")
        self.prd_mapping = self.load_yaml("prd-mapping.yaml")
        self.current_stage = self.get_current_stage()
        
    def load_yaml(self, filename):
        """Carrega arquivo YAML de configuração"""
        try:
            with open(self.config_path / filename, 'r') as f:
                return yaml.safe_load(f)
        except FileNotFoundError:
            print(f"❌ Arquivo {filename} não encontrado!")
            return {}
    
    def get_current_stage(self):
        """Determina a etapa atual do projeto"""
        # Verifica arquivo de estado ou usa lógica de detecção
        state_file = Path(".framework/current_stage.json")
        if state_file.exists():
            with open(state_file, 'r') as f:
                return json.load(f).get('current_stage', 'stage_1')
        return 'stage_1'
    
    def set_current_stage(self, stage):
        """Define a etapa atual do projeto"""
        state_file = Path(".framework/current_stage.json")
        state_data = {
            'current_stage': stage,
            'updated_at': datetime.now().isoformat(),
            'previous_stages': self.get_completed_stages()
        }
        with open(state_file, 'w') as f:
            json.dump(state_data, f, indent=2)
    
    def get_completed_stages(self):
        """Retorna lista de etapas completadas"""
        # Implementar lógica baseada em arquivos/markers de conclusão
        completed = []
        for stage_name in self.stages_config.get('stages', {}):
            marker_file = Path(f".framework/stages/{stage_name}_completed.marker")
            if marker_file.exists():
                completed.append(stage_name)
        return completed
    
    def validate_current_stage(self):
        """Valida a etapa atual contra requisitos do PRD"""
        stage_config = self.stages_config['stages'].get(self.current_stage, {})
        prd_validations = self.prd_mapping['stage_validations'].get(self.current_stage, {})
        
        print(f"🔍 Validando {stage_config.get('name', self.current_stage)}...")
        
        results = {
            'stage': self.current_stage,
            'stage_name': stage_config.get('name'),
            'validation_passed': True,
            'requirements_met': [],
            'requirements_missing': [],
            'warnings': [],
            'recommendations': []
        }
        
        # Validar requisitos PRD
        prd_requirements = prd_validations.get('prd_requirements', [])
        for requirement in prd_requirements:
            if self.check_prd_requirement(requirement):
                results['requirements_met'].append(requirement)
                print(f"  ✅ {requirement}")
            else:
                results['requirements_missing'].append(requirement)
                results['validation_passed'] = False
                print(f"  ❌ {requirement}")
        
        # Verificar deliverables da etapa
        deliverables = stage_config.get('key_deliverables', [])
        for deliverable in deliverables:
            if not self.check_deliverable_complete(deliverable):
                results['warnings'].append(f"Deliverable pendente: {deliverable}")
                print(f"  ⚠️  {deliverable} - pendente")
        
        return results
    
    def check_prd_requirement(self, requirement):
        """Verifica se um requisito específico do PRD foi atendido"""
        # Implementar lógica específica para cada tipo de requisito
        # Por enquanto, verifica se existe documentação relacionada
        
        requirement_checks = {
            'problem_statement_defined': lambda: self.file_exists("docs/prd/problem-statement.md"),
            'customer_impact_quantified': lambda: self.file_contains("docs/prd/", "impacto"),
            'target_audience_identified': lambda: self.file_exists("docs/prd/personas.md"),
            'technical_architecture_defined': lambda: self.file_exists("docs/architecture/"),
            'user_journeys_mapped': lambda: self.file_exists("docs/ux/user-journeys.md"),
            'design_system_requirements_met': lambda: self.file_exists("docs/design/design-system.md"),
            'features_implemented_per_prd': lambda: self.check_implementation_status(),
        }
        
        check_function = requirement_checks.get(requirement, lambda: False)
        return check_function()
    
    def file_exists(self, path):
        """Verifica se arquivo ou diretório existe"""
        return Path(path).exists()
    
    def file_contains(self, directory, keyword):
        """Verifica se algum arquivo no diretório contém a palavra-chave"""
        try:
            for file_path in Path(directory).rglob("*.md"):
                with open(file_path, 'r', encoding='utf-8') as f:
                    if keyword.lower() in f.read().lower():
                        return True
        except:
            pass
        return False
    
    def check_deliverable_complete(self, deliverable):
        """Verifica se um deliverable foi completado"""
        # Implementar lógica baseada em markers ou arquivos específicos
        marker_file = Path(f".framework/deliverables/{deliverable}.completed")
        return marker_file.exists()
    
    def check_implementation_status(self):
        """Verifica status de implementação das features"""
        # Implementar lógica baseada em código, testes, etc.
        # Por exemplo, verificar se existem testes passando
        return Path("tests/").exists() and any(Path("tests/").rglob("*.py"))
    
    def generate_validation_report(self):
        """Gera relatório completo de validação"""
        results = self.validate_current_stage()
        
        report = f"""
# Relatório de Validação PRD-Framework
**Data**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
**Etapa Atual**: {results['stage_name']} ({results['stage']})

## Status Geral
{'✅ APROVADO' if results['validation_passed'] else '❌ PENDENTE'}

## Requisitos PRD Atendidos ({len(results['requirements_met'])})
{chr(10).join(['- ✅ ' + req for req in results['requirements_met']])}

## Requisitos PRD Pendentes ({len(results['requirements_missing'])})
{chr(10).join(['- ❌ ' + req for req in results['requirements_missing']])}

## Avisos ({len(results['warnings'])})
{chr(10).join(['- ⚠️ ' + warning for warning in results['warnings']])}

## Próximas Ações Recomendadas
{self.get_next_actions()}
"""
        
        # Salvar relatório
        report_file = Path(f"docs/reports/validation-{datetime.now().strftime('%Y%m%d-%H%M%S')}.md")
        report_file.parent.mkdir(parents=True, exist_ok=True)
        
        with open(report_file, 'w', encoding='utf-8') as f:
            f.write(report)
        
        print(f"📊 Relatório salvo em: {report_file}")
        return results
    
    def get_next_actions(self):
        """Gera lista de próximas ações recomendadas"""
        current_config = self.stages_config['stages'].get(self.current_stage, {})
        next_actions = []
        
        # Ações baseadas na etapa atual
        if self.current_stage == 'stage_1':
            next_actions = [
                "Completar entrevistas com clientes",
                "Documentar declaração do problema",
                "Quantificar impacto no cliente",
                "Estabelecer métricas de sucesso"
            ]
        elif self.current_stage == 'stage_2':
            next_actions = [
                "Finalizar design da arquitetura técnica",
                "Documentar requisitos de integração",
                "Validar requisitos de segurança",
                "Planejar estratégia de escalabilidade"
            ]
        # Adicionar mais etapas conforme necessário
        
        return chr(10).join(['- ' + action for action in next_actions])
    
    def advance_to_next_stage(self):
        """Avança para a próxima etapa do framework"""
        if not self.validate_current_stage()['validation_passed']:
            print("❌ Não é possível avançar. Validação da etapa atual falhou.")
            return False
        
        stages = list(self.stages_config['stages'].keys())
        current_index = stages.index(self.current_stage)
        
        if current_index < len(stages) - 1:
            next_stage = stages[current_index + 1]
            self.mark_stage_completed(self.current_stage)
            self.set_current_stage(next_stage)
            print(f"🎉 Avançado para: {self.stages_config['stages'][next_stage]['name']}")
            return True
        else:
            print("🏁 Todas as etapas foram completadas!")
            return True
    
    def mark_stage_completed(self, stage):
        """Marca uma etapa como completada"""
        marker_file = Path(f".framework/stages/{stage}_completed.marker")
        marker_file.parent.mkdir(parents=True, exist_ok=True)
        
        with open(marker_file, 'w') as f:
            f.write(f"Completed at: {datetime.now().isoformat()}")

def main():
    """Função principal do script"""
    import sys
    
    validator = PRDFrameworkValidator()
    
    if len(sys.argv) > 1:
        command = sys.argv[1]
        
        if command == "validate":
            validator.generate_validation_report()
        elif command == "advance":
            validator.advance_to_next_stage()
        elif command == "status":
            results = validator.validate_current_stage()
            print(f"Status: {'✅ OK' if results['validation_passed'] else '❌ PENDENTE'}")
        elif command == "set-stage" and len(sys.argv) > 2:
            stage = sys.argv[2]
            validator.set_current_stage(stage)
            print(f"Etapa definida para: {stage}")
        else:
            print("Comandos disponíveis: validate, advance, status, set-stage")
    else:
        print("🔍 Executando validação completa...")
        validator.generate_validation_report()

if __name__ == "__main__":
    main()