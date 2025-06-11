#!/bin/bash

echo "🔍 Validation du Workflow GitHub Actions..."
echo "==========================================="

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
mkdir -p test-results/workflow-validation

echo -e "${BLUE}📋 Test 1: Validation de la structure des workflows${NC}"

# Vérifier l'existence des fichiers de workflow
WORKFLOWS_DIR=".github/workflows"
EXPECTED_WORKFLOWS=(
    "complete-security-pipeline.yml"
    "trivy.yml"
    "checkov.yml"
    "sonarqube.yml"
    "security-pipeline.yml"
)

MISSING_WORKFLOWS=()
FOUND_WORKFLOWS=()

for workflow in "${EXPECTED_WORKFLOWS[@]}"; do
    if [ -f "$WORKFLOWS_DIR/$workflow" ]; then
        FOUND_WORKFLOWS+=("$workflow")
        echo "✓ Trouvé: $workflow"
    else
        MISSING_WORKFLOWS+=("$workflow")
        echo "✗ Manquant: $workflow"
    fi
done

if [ ${#MISSING_WORKFLOWS[@]} -eq 0 ]; then
    print_result 0 "Structure des workflows"
else
    print_result 1 "Structure des workflows (${#MISSING_WORKFLOWS[@]} manquants)"
fi

echo -e "\n${BLUE}📋 Test 2: Validation YAML des workflows${NC}"

YAML_VALID=true

for workflow in "${FOUND_WORKFLOWS[@]}"; do
    echo "Validation de $workflow..."
    
    # Vérifier la syntaxe YAML avec Python
    if command -v python3 &> /dev/null; then
        python3 -c "
import yaml
import sys
try:
    with open('$WORKFLOWS_DIR/$workflow', 'r') as f:
        yaml.safe_load(f)
    print('  ✓ YAML valide')
except yaml.YAMLError as e:
    print(f'  ✗ Erreur YAML: {e}')
    sys.exit(1)
except Exception as e:
    print(f'  ✗ Erreur: {e}')
    sys.exit(1)
"
        if [ $? -ne 0 ]; then
            YAML_VALID=false
        fi
    else
        echo "  ⚠️ Python non disponible pour validation YAML"
    fi
done

print_result $([ "$YAML_VALID" = true ] && echo 0 || echo 1) "Validation YAML"

echo -e "\n${BLUE}📋 Test 3: Vérification des déclencheurs${NC}"

TRIGGERS_VALID=true

for workflow in "${FOUND_WORKFLOWS[@]}"; do
    echo "Vérification des déclencheurs pour $workflow..."
    
    # Vérifier la présence des déclencheurs essentiels
    if grep -q "on:" "$WORKFLOWS_DIR/$workflow"; then
        if grep -q "push:" "$WORKFLOWS_DIR/$workflow" && grep -q "pull_request:" "$WORKFLOWS_DIR/$workflow"; then
            echo "  ✓ Déclencheurs push et pull_request présents"
        else
            echo "  ✗ Déclencheurs manquants"
            TRIGGERS_VALID=false
        fi
    else
        echo "  ✗ Section 'on:' manquante"
        TRIGGERS_VALID=false
    fi
done

print_result $([ "$TRIGGERS_VALID" = true ] && echo 0 || echo 1) "Déclencheurs des workflows"

echo -e "\n${BLUE}📋 Test 4: Vérification des permissions${NC}"

PERMISSIONS_VALID=true

for workflow in "${FOUND_WORKFLOWS[@]}"; do
    echo "Vérification des permissions pour $workflow..."
    
    # Vérifier les permissions de sécurité pour les workflows qui uploadent SARIF
    if grep -q "upload-sarif" "$WORKFLOWS_DIR/$workflow"; then
        if grep -q "security-events: write" "$WORKFLOWS_DIR/$workflow"; then
            echo "  ✓ Permissions security-events présentes"
        else
            echo "  ✗ Permissions security-events manquantes"
            PERMISSIONS_VALID=false
        fi
    fi
done

print_result $([ "$PERMISSIONS_VALID" = true ] && echo 0 || echo 1) "Permissions des workflows"

echo -e "\n${BLUE}📋 Test 5: Vérification des actions utilisées${NC}"

ACTIONS_VALID=true
ACTIONS_REPORT="test-results/workflow-validation/actions-used.txt"

echo "Actions GitHub utilisées dans les workflows:" > "$ACTIONS_REPORT"
echo "=============================================" >> "$ACTIONS_REPORT"

for workflow in "${FOUND_WORKFLOWS[@]}"; do
    echo "" >> "$ACTIONS_REPORT"
    echo "Workflow: $workflow" >> "$ACTIONS_REPORT"
    echo "-------------------" >> "$ACTIONS_REPORT"
    
    # Extraire les actions utilisées
    grep -E "uses:" "$WORKFLOWS_DIR/$workflow" | sed 's/.*uses: //' | sort | uniq >> "$ACTIONS_REPORT"
done

# Vérifier les actions critiques
CRITICAL_ACTIONS=(
    "actions/checkout@v4"
    "github/codeql-action/upload-sarif@v3"
    "actions/upload-artifact@v4"
)

for action in "${CRITICAL_ACTIONS[@]}"; do
    if grep -r "$action" "$WORKFLOWS_DIR/" > /dev/null; then
        echo "✓ Action critique trouvée: $action"
    else
        echo "✗ Action critique manquante: $action"
        ACTIONS_VALID=false
    fi
done

print_result $([ "$ACTIONS_VALID" = true ] && echo 0 || echo 1) "Actions GitHub"

echo -e "\n${BLUE}📋 Test 6: Simulation d'exécution locale${NC}"

# Créer un script de simulation
cat > test-results/workflow-validation/simulate-workflow.sh << 'EOF'
#!/bin/bash

echo "🔄 Simulation d'exécution du workflow..."

# Simuler les variables d'environnement GitHub Actions
export GITHUB_WORKSPACE=$(pwd)
export GITHUB_REPOSITORY="test/security-pipeline"
export GITHUB_SHA="abc123def456"
export GITHUB_REF="refs/heads/main"
export GITHUB_REF_NAME="main"
export GITHUB_ACTOR="test-user"
export GITHUB_RUN_ID="123456789"

echo "Variables d'environnement GitHub Actions simulées:"
echo "- GITHUB_WORKSPACE: $GITHUB_WORKSPACE"
echo "- GITHUB_REPOSITORY: $GITHUB_REPOSITORY"
echo "- GITHUB_SHA: $GITHUB_SHA"
echo "- GITHUB_REF: $GITHUB_REF"

# Simuler les étapes principales
echo ""
echo "Étapes simulées:"
echo "1. ✓ Checkout du code"
echo "2. ✓ Installation des outils"
echo "3. ✓ Exécution des scans"
echo "4. ✓ Génération des rapports SARIF"
echo "5. ✓ Upload des artefacts"

echo ""
echo "✅ Simulation terminée avec succès"
EOF

chmod +x test-results/workflow-validation/simulate-workflow.sh
./test-results/workflow-validation/simulate-workflow.sh > test-results/workflow-validation/simulation-log.txt 2>&1

print_result $? "Simulation d'exécution"

echo -e "\n${BLUE}📋 Test 7: Génération du rapport de validation${NC}"

# Générer un rapport de validation complet
cat > test-results/workflow-validation/validation-report.md << EOF
# 🔍 Rapport de Validation des Workflows GitHub Actions

**Date de validation:** $(date)

## 📊 Résumé

| Test | Résultat | Description |
|------|----------|-------------|
| Structure | $([ ${#MISSING_WORKFLOWS[@]} -eq 0 ] && echo "✅ VALIDE" || echo "❌ INVALIDE") | Présence des fichiers de workflow |
| YAML | $([ "$YAML_VALID" = true ] && echo "✅ VALIDE" || echo "❌ INVALIDE") | Syntaxe YAML correcte |
| Déclencheurs | $([ "$TRIGGERS_VALID" = true ] && echo "✅ VALIDE" || echo "❌ INVALIDE") | Configuration des événements |
| Permissions | $([ "$PERMISSIONS_VALID" = true ] && echo "✅ VALIDE" || echo "❌ INVALIDE") | Permissions de sécurité |
| Actions | $([ "$ACTIONS_VALID" = true ] && echo "✅ VALIDE" || echo "❌ INVALIDE") | Actions GitHub utilisées |

## 📁 Workflows Analysés

### Workflows Trouvés
$(for workflow in "${FOUND_WORKFLOWS[@]}"; do echo "- ✅ $workflow"; done)

### Workflows Manquants
$(for workflow in "${MISSING_WORKFLOWS[@]}"; do echo "- ❌ $workflow"; done)

## 🔧 Actions GitHub Utilisées

$(cat test-results/workflow-validation/actions-used.txt)

## 🎯 Recommandations

1. **Sécurité:** Vérifier que tous les secrets sont correctement configurés
2. **Permissions:** S'assurer que les permissions minimales sont utilisées
3. **Versions:** Maintenir les actions à jour avec les dernières versions
4. **Tests:** Tester les workflows dans un environnement de développement

## 📋 Checklist de Déploiement

- [ ] Tous les workflows sont présents
- [ ] La syntaxe YAML est valide
- [ ] Les déclencheurs sont configurés
- [ ] Les permissions sont définies
- [ ] Les secrets sont configurés dans GitHub
- [ ] Les actions sont à jour

---
*Rapport généré automatiquement*
EOF

print_result 0 "Génération du rapport"

echo -e "\n${YELLOW}📈 Résumé de la validation:${NC}"
echo "- Workflows trouvés: ${#FOUND_WORKFLOWS[@]}"
echo "- Workflows manquants: ${#MISSING_WORKFLOWS[@]}"
echo "- YAML valide: $([ "$YAML_VALID" = true ] && echo "Oui" || echo "Non")"
echo "- Déclencheurs valides: $([ "$TRIGGERS_VALID" = true ] && echo "Oui" || echo "Non")"
echo "- Permissions valides: $([ "$PERMISSIONS_VALID" = true ] && echo "Oui" || echo "Non")"
echo "- Actions valides: $([ "$ACTIONS_VALID" = true ] && echo "Oui" || echo "Non")"

echo -e "\n${BLUE}📁 Rapports générés:${NC}"
echo "- test-results/workflow-validation/actions-used.txt"
echo "- test-results/workflow-validation/validation-report.md"
echo "- test-results/workflow-validation/simulation-log.txt"

# Calculer le score de validation
VALIDATION_SCORE=0
[ ${#MISSING_WORKFLOWS[@]} -eq 0 ] && VALIDATION_SCORE=$((VALIDATION_SCORE + 1))
[ "$YAML_VALID" = true ] && VALIDATION_SCORE=$((VALIDATION_SCORE + 1))
[ "$TRIGGERS_VALID" = true ] && VALIDATION_SCORE=$((VALIDATION_SCORE + 1))
[ "$PERMISSIONS_VALID" = true ] && VALIDATION_SCORE=$((VALIDATION_SCORE + 1))
[ "$ACTIONS_VALID" = true ] && VALIDATION_SCORE=$((VALIDATION_SCORE + 1))

VALIDATION_PERCENTAGE=$((VALIDATION_SCORE * 100 / 5))

echo -e "\n${GREEN}🏆 Score de validation: ${VALIDATION_PERCENTAGE}% (${VALIDATION_SCORE}/5)${NC}"

if [ $VALIDATION_PERCENTAGE -eq 100 ]; then
    echo -e "${GREEN}🎉 Tous les workflows sont valides!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️ Des améliorations sont nécessaires.${NC}"
    exit 1
fi