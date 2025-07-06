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
