#!/bin/bash

echo "🚀 Exécution de tous les tests de sécurité..."
echo "============================================="

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Fonction pour afficher les résultats
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

# Fonction pour afficher une section
print_section() {
    echo -e "\n${PURPLE}===========================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}===========================================${NC}\n"
}

# Créer le dossier de résultats principal
mkdir -p test-results
rm -rf test-results/* 2>/dev/null

# Variables pour le résumé
TRIVY_RESULT=0
CHECKOV_RESULT=0
SONARQUBE_RESULT=0

START_TIME=$(date +%s)

print_section "🛡️ PHASE 1: TESTS TRIVY"

# Exécuter les tests Trivy
if [ -f "tests/test-scripts/run-trivy-tests.sh" ]; then
    chmod +x tests/test-scripts/run-trivy-tests.sh
    ./tests/test-scripts/run-trivy-tests.sh
    TRIVY_RESULT=$?
else
    echo -e "${RED}❌ Script Trivy non trouvé${NC}"
    TRIVY_RESULT=1
fi

print_section "⚙️ PHASE 2: TESTS CHECKOV"

# Exécuter les tests Checkov
if [ -f "tests/test-scripts/run-checkov-tests.sh" ]; then
    chmod +x tests/test-scripts/run-checkov-tests.sh
    ./tests/test-scripts/run-checkov-tests.sh
    CHECKOV_RESULT=$?
else
    echo -e "${RED}❌ Script Checkov non trouvé${NC}"
    CHECKOV_RESULT=1
fi

print_section "📊 PHASE 3: TESTS SONARQUBE"

# Exécuter les tests SonarQube
if [ -f "tests/test-scripts/run-sonarqube-tests.sh" ]; then
    chmod +x tests/test-scripts/run-sonarqube-tests.sh
    ./tests/test-scripts/run-sonarqube-tests.sh
    SONARQUBE_RESULT=$?
else
    echo -e "${RED}❌ Script SonarQube non trouvé${NC}"
    SONARQUBE_RESULT=1
fi

print_section "📋 PHASE 4: GÉNÉRATION DU RAPPORT CONSOLIDÉ"

# Calculer le temps d'exécution
END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))

# Générer un rapport consolidé
cat > test-results/consolidated-report.md << EOF
# 🛡️ Rapport Consolidé des Tests de Sécurité

**Date d'exécution:** $(date)
**Durée totale:** ${EXECUTION_TIME}s

## 📊 Résumé Exécutif

| Outil | Status | Résultat |
|-------|--------|----------|
| 🛡️ **Trivy** | $([ $TRIVY_RESULT -eq 0 ] && echo "✅ SUCCÈS" || echo "❌ ÉCHEC") | Scanner de vulnérabilités et secrets |
| ⚙️ **Checkov** | $([ $CHECKOV_RESULT -eq 0 ] && echo "✅ SUCCÈS" || echo "❌ ÉCHEC") | Analyseur de configuration IaC |
| 📊 **SonarQube** | $([ $SONARQUBE_RESULT -eq 0 ] && echo "✅ SUCCÈS" || echo "❌ ÉCHEC") | Plateforme de qualité du code |

## 🎯 Détails des Tests

### Trivy - Scanner de Vulnérabilités
- **Vulnérabilités NPM:** Analysées dans package.json
- **Vulnérabilités Python:** Analysées dans requirements.txt
- **Secrets exposés:** Détection dans tous les fichiers
- **Configuration Docker:** Analyse du Dockerfile
- **Format SARIF:** Rapport généré pour GitHub Security

### Checkov - Analyseur IaC
- **Terraform:** Configurations AWS analysées
- **Dockerfile:** Bonnes pratiques de sécurité
- **Kubernetes:** Manifests de déploiement
- **Secrets:** Détection de clés exposées
- **Format SARIF:** Rapport généré pour GitHub Security

### SonarQube - Qualité du Code
- **Code JavaScript:** Analyse statique complète
- **Code Python:** Détection de vulnérabilités
- **Métriques:** Bugs, vulnérabilités, code smells
- **Quality Gate:** Validation des seuils de qualité

## 📁 Fichiers de Test Analysés

### Fichiers Vulnérables Intentionnels
- \`tests/vulnerable-files/package.json\` - Dépendances NPM vulnérables
- \`tests/vulnerable-files/requirements.txt\` - Dépendances Python vulnérables
- \`tests/vulnerable-files/Dockerfile\` - Configuration Docker non sécurisée
- \`tests/vulnerable-files/terraform/main.tf\` - Infrastructure AWS vulnérable
- \`tests/vulnerable-files/kubernetes/deployment.yaml\` - Déploiement K8s non sécurisé
- \`tests/vulnerable-files/secrets.env\` - Secrets exposés
- \`tests/vulnerable-files/src/app.js\` - Code JavaScript vulnérable
- \`tests/vulnerable-files/src/app.py\` - Code Python vulnérable

## 🔗 Liens Utiles

- **Résultats Trivy:** \`test-results/trivy/\`
- **Résultats Checkov:** \`test-results/checkov/\`
- **Résultats SonarQube:** \`test-results/sonarqube/\`
- **Dashboard SonarQube:** http://localhost:9000/dashboard?id=security-test-project

## 🎯 Recommandations

1. **Intégrer dans CI/CD:** Utiliser le workflow GitHub Actions fourni
2. **Corriger les vulnérabilités:** Mettre à jour les dépendances identifiées
3. **Améliorer les configurations:** Appliquer les recommandations Checkov
4. **Monitorer la qualité:** Suivre les métriques SonarQube régulièrement

---
*Rapport généré automatiquement par le pipeline DevSecOps*
EOF

print_section "📈 RÉSUMÉ FINAL"

echo -e "${BLUE}🎯 Résultats des Tests:${NC}"
print_result $TRIVY_RESULT "Tests Trivy"
print_result $CHECKOV_RESULT "Tests Checkov"
print_result $SONARQUBE_RESULT "Tests SonarQube"

echo -e "\n${BLUE}📊 Statistiques:${NC}"
echo "- Durée totale d'exécution: ${EXECUTION_TIME}s"
echo "- Fichiers de test analysés: 8"
echo "- Outils de sécurité testés: 3"
echo "- Rapport consolidé: test-results/consolidated-report.md"

echo -e "\n${BLUE}📁 Résultats disponibles dans:${NC}"
echo "- test-results/trivy/ - Rapports Trivy"
echo "- test-results/checkov/ - Rapports Checkov"
echo "- test-results/sonarqube/ - Rapports SonarQube"
echo "- test-results/consolidated-report.md - Rapport consolidé"

# Calculer le score global
TOTAL_TESTS=3
PASSED_TESTS=0
[ $TRIVY_RESULT -eq 0 ] && PASSED_TESTS=$((PASSED_TESTS + 1))
[ $CHECKOV_RESULT -eq 0 ] && PASSED_TESTS=$((PASSED_TESTS + 1))
[ $SONARQUBE_RESULT -eq 0 ] && PASSED_TESTS=$((PASSED_TESTS + 1))

SCORE=$((PASSED_TESTS * 100 / TOTAL_TESTS))

echo -e "\n${PURPLE}🏆 Score Global: ${SCORE}% (${PASSED_TESTS}/${TOTAL_TESTS} tests réussis)${NC}"

if [ $SCORE -eq 100 ]; then
    echo -e "${GREEN}🎉 Tous les tests de sécurité ont réussi!${NC}"
    exit 0
elif [ $SCORE -ge 66 ]; then
    echo -e "${YELLOW}⚠️ La plupart des tests ont réussi, mais des améliorations sont possibles.${NC}"
    exit 0
else
    echo -e "${RED}❌ Plusieurs tests ont échoué. Veuillez vérifier la configuration.${NC}"
    exit 1
fi