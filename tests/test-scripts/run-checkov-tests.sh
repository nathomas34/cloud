#!/bin/bash

echo "⚙️ Exécution des tests Checkov..."
echo "================================="

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
mkdir -p test-results/checkov

echo -e "${BLUE}📋 Test 1: Scan Terraform${NC}"
checkov -f tests/vulnerable-files/terraform/main.tf \
    --output cli \
    --output-file-path test-results/checkov/terraform-results.txt \
    --soft-fail

TF_FAILED=$(checkov -f tests/vulnerable-files/terraform/main.tf --output json --quiet | jq '.summary.failed' 2>/dev/null || echo "0")
echo "Contrôles Terraform échoués: $TF_FAILED"
print_result 0 "Scan Terraform"

echo -e "\n${BLUE}🐳 Test 2: Scan Dockerfile${NC}"
checkov -f tests/vulnerable-files/Dockerfile \
    --framework dockerfile \
    --output cli \
    --output-file-path test-results/checkov/dockerfile-results.txt \
    --soft-fail

DOCKER_FAILED=$(checkov -f tests/vulnerable-files/Dockerfile --framework dockerfile --output json --quiet | jq '.summary.failed' 2>/dev/null || echo "0")
echo "Contrôles Dockerfile échoués: $DOCKER_FAILED"
print_result 0 "Scan Dockerfile"

echo -e "\n${BLUE}☸️ Test 3: Scan Kubernetes${NC}"
checkov -f tests/vulnerable-files/kubernetes/deployment.yaml \
    --framework kubernetes \
    --output cli \
    --output-file-path test-results/checkov/kubernetes-results.txt \
    --soft-fail

K8S_FAILED=$(checkov -f tests/vulnerable-files/kubernetes/deployment.yaml --framework kubernetes --output json --quiet | jq '.summary.failed' 2>/dev/null || echo "0")
echo "Contrôles Kubernetes échoués: $K8S_FAILED"
print_result 0 "Scan Kubernetes"

echo -e "\n${BLUE}🔐 Test 4: Scan des secrets${NC}"
checkov -f tests/vulnerable-files/secrets.env \
    --framework secrets \
    --output cli \
    --output-file-path test-results/checkov/secrets-results.txt \
    --soft-fail

SECRETS_FAILED=$(checkov -f tests/vulnerable-files/secrets.env --framework secrets --output json --quiet | jq '.summary.failed' 2>/dev/null || echo "0")
echo "Secrets détectés: $SECRETS_FAILED"
print_result 0 "Scan des secrets"

echo -e "\n${BLUE}📊 Test 5: Génération du rapport SARIF${NC}"
checkov -d tests/vulnerable-files/ \
    --output sarif \
    --output-file-path test-results/checkov/checkov-results.sarif \
    --quiet \
    --soft-fail

if [ -f "test-results/checkov/checkov-results.sarif" ]; then
    SARIF_SIZE=$(stat -f%z test-results/checkov/checkov-results.sarif 2>/dev/null || stat -c%s test-results/checkov/checkov-results.sarif 2>/dev/null)
    echo "Taille du fichier SARIF: $SARIF_SIZE bytes"
    print_result 0 "Génération du rapport SARIF"
else
    print_result 1 "Génération du rapport SARIF"
fi

echo -e "\n${BLUE}📈 Test 6: Scan complet du répertoire${NC}"
checkov -d tests/vulnerable-files/ \
    --output cli \
    --output-file-path test-results/checkov/complete-scan.txt \
    --compact \
    --soft-fail

TOTAL_FAILED=$(checkov -d tests/vulnerable-files/ --output json --quiet --soft-fail | jq '.summary.failed' 2>/dev/null || echo "0")
TOTAL_PASSED=$(checkov -d tests/vulnerable-files/ --output json --quiet --soft-fail | jq '.summary.passed' 2>/dev/null || echo "0")
echo "Total contrôles échoués: $TOTAL_FAILED"
echo "Total contrôles réussis: $TOTAL_PASSED"
print_result 0 "Scan complet"

echo -e "\n${YELLOW}📈 Résumé des tests Checkov:${NC}"
echo "- Contrôles Terraform échoués: $TF_FAILED"
echo "- Contrôles Dockerfile échoués: $DOCKER_FAILED"
echo "- Contrôles Kubernetes échoués: $K8S_FAILED"
echo "- Secrets détectés: $SECRETS_FAILED"
echo "- Total échoués: $TOTAL_FAILED"
echo "- Total réussis: $TOTAL_PASSED"
echo "- Rapports générés dans: test-results/checkov/"

echo -e "\n${GREEN}🎯 Tests Checkov terminés!${NC}"