#!/bin/bash

echo "🛡️ Exécution des tests Trivy..."
echo "=================================="

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les résultats
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

# Créer le dossier de résultats
mkdir -p test-results/trivy

echo -e "${BLUE}📋 Test 1: Scan des vulnérabilités de dépendances${NC}"
trivy fs tests/vulnerable-files/package.json \
    --format table \
    --output test-results/trivy/vulnerabilities-npm.txt \
    --severity CRITICAL,HIGH,MEDIUM

VULN_COUNT=$(trivy fs tests/vulnerable-files/package.json --format json | jq '.Results[0].Vulnerabilities | length' 2>/dev/null || echo "0")
echo "Vulnérabilités trouvées: $VULN_COUNT"
print_result $? "Scan des vulnérabilités NPM"

echo -e "\n${BLUE}📋 Test 2: Scan des vulnérabilités Python${NC}"
trivy fs tests/vulnerable-files/requirements.txt \
    --format table \
    --output test-results/trivy/vulnerabilities-python.txt \
    --severity CRITICAL,HIGH,MEDIUM

PYTHON_VULN_COUNT=$(trivy fs tests/vulnerable-files/requirements.txt --format json | jq '.Results[0].Vulnerabilities | length' 2>/dev/null || echo "0")
echo "Vulnérabilités Python trouvées: $PYTHON_VULN_COUNT"
print_result $? "Scan des vulnérabilités Python"

echo -e "\n${BLUE}🔐 Test 3: Scan des secrets exposés${NC}"
trivy fs tests/vulnerable-files/ \
    --scanners secret \
    --format table \
    --output test-results/trivy/secrets.txt

SECRET_COUNT=$(trivy fs tests/vulnerable-files/ --scanners secret --format json | jq '[.Results[]?.Secrets[]?] | length' 2>/dev/null || echo "0")
echo "Secrets trouvés: $SECRET_COUNT"
print_result $? "Scan des secrets"

echo -e "\n${BLUE}🐳 Test 4: Scan du Dockerfile${NC}"
trivy config tests/vulnerable-files/Dockerfile \
    --format table \
    --output test-results/trivy/dockerfile-misconfigs.txt

print_result $? "Scan du Dockerfile"

echo -e "\n${BLUE}📊 Test 5: Génération du rapport SARIF${NC}"
trivy fs tests/vulnerable-files/ \
    --scanners vuln,secret \
    --format sarif \
    --output test-results/trivy/trivy-results.sarif

if [ -f "test-results/trivy/trivy-results.sarif" ]; then
    SARIF_SIZE=$(stat -f%z test-results/trivy/trivy-results.sarif 2>/dev/null || stat -c%s test-results/trivy/trivy-results.sarif 2>/dev/null)
    echo "Taille du fichier SARIF: $SARIF_SIZE bytes"
    print_result 0 "Génération du rapport SARIF"
else
    print_result 1 "Génération du rapport SARIF"
fi

echo -e "\n${YELLOW}📈 Résumé des tests Trivy:${NC}"
echo "- Vulnérabilités NPM: $VULN_COUNT"
echo "- Vulnérabilités Python: $PYTHON_VULN_COUNT"
echo "- Secrets détectés: $SECRET_COUNT"
echo "- Rapports générés dans: test-results/trivy/"

echo -e "\n${GREEN}🎯 Tests Trivy terminés!${NC}"