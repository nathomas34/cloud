#!/bin/bash

echo "📊 Exécution des tests SonarQube..."
echo "==================================="

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

# Vérifier si SonarQube est accessible
SONAR_HOST=${SONAR_HOST_URL:-"http://localhost:9000"}
SONAR_TOKEN=${SONAR_TOKEN:-""}

echo -e "${BLUE}🔍 Test 1: Vérification de la connectivité SonarQube${NC}"
if curl -s "$SONAR_HOST/api/system/status" > /dev/null; then
    echo "SonarQube accessible à: $SONAR_HOST"
    print_result 0 "Connectivité SonarQube"
else
    echo "⚠️ SonarQube non accessible à: $SONAR_HOST"
    echo "Veuillez démarrer SonarQube avec: docker run -d --name sonarqube -p 9000:9000 sonarqube:latest"
    print_result 1 "Connectivité SonarQube"
    exit 1
fi

# Créer le dossier de résultats
mkdir -p test-results/sonarqube

# Créer un projet de test temporaire
TEST_PROJECT_KEY="security-test-project"
TEST_PROJECT_NAME="Security Test Project"

echo -e "\n${BLUE}📋 Test 2: Configuration du projet de test${NC}"

# Créer un fichier sonar-project.properties pour les tests
cat > tests/vulnerable-files/sonar-project.properties << EOF
sonar.projectKey=$TEST_PROJECT_KEY
sonar.projectName=$TEST_PROJECT_NAME
sonar.projectVersion=1.0
sonar.sources=src
sonar.sourceEncoding=UTF-8
sonar.language=js,py
sonar.exclusions=**/node_modules/**,**/*.test.js,**/*.spec.js
sonar.javascript.lcov.reportPaths=coverage/lcov.info
sonar.python.coverage.reportPaths=coverage.xml
EOF

print_result 0 "Configuration du projet"

echo -e "\n${BLUE}📊 Test 3: Installation de SonarScanner${NC}"

# Vérifier si SonarScanner est installé
if ! command -v sonar-scanner &> /dev/null; then
    echo "Installation de SonarScanner..."
    
    # Télécharger et installer SonarScanner
    SCANNER_VERSION="5.0.1.3006"
    wget -q "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SCANNER_VERSION}-linux.zip" -O sonar-scanner.zip
    
    if [ $? -eq 0 ]; then
        unzip -q sonar-scanner.zip
        export PATH="$PATH:$(pwd)/sonar-scanner-${SCANNER_VERSION}-linux/bin"
        print_result 0 "Installation SonarScanner"
    else
        print_result 1 "Installation SonarScanner"
        echo "Erreur lors du téléchargement de SonarScanner"
        exit 1
    fi
else
    echo "SonarScanner déjà installé"
    print_result 0 "SonarScanner disponible"
fi

echo -e "\n${BLUE}🔍 Test 4: Analyse du code JavaScript${NC}"

cd tests/vulnerable-files

# Exécuter l'analyse SonarQube
if [ -n "$SONAR_TOKEN" ]; then
    sonar-scanner \
        -Dsonar.projectKey=$TEST_PROJECT_KEY \
        -Dsonar.projectName="$TEST_PROJECT_NAME" \
        -Dsonar.sources=src \
        -Dsonar.host.url=$SONAR_HOST \
        -Dsonar.token=$SONAR_TOKEN \
        -Dsonar.sourceEncoding=UTF-8 \
        -Dsonar.exclusions="**/node_modules/**" \
        -Dsonar.javascript.file.suffixes=.js \
        -Dsonar.python.file.suffixes=.py \
        > ../../test-results/sonarqube/analysis-log.txt 2>&1
    
    ANALYSIS_RESULT=$?
else
    echo "⚠️ SONAR_TOKEN non défini. Utilisation des identifiants par défaut..."
    sonar-scanner \
        -Dsonar.projectKey=$TEST_PROJECT_KEY \
        -Dsonar.projectName="$TEST_PROJECT_NAME" \
        -Dsonar.sources=src \
        -Dsonar.host.url=$SONAR_HOST \
        -Dsonar.login=admin \
        -Dsonar.password=admin \
        -Dsonar.sourceEncoding=UTF-8 \
        -Dsonar.exclusions="**/node_modules/**" \
        -Dsonar.javascript.file.suffixes=.js \
        -Dsonar.python.file.suffixes=.py \
        > ../../test-results/sonarqube/analysis-log.txt 2>&1
    
    ANALYSIS_RESULT=$?
fi

cd ../..

print_result $ANALYSIS_RESULT "Analyse SonarQube"

echo -e "\n${BLUE}📈 Test 5: Récupération des métriques${NC}"

# Attendre que l'analyse soit terminée
sleep 10

# Récupérer les métriques du projet
if [ -n "$SONAR_TOKEN" ]; then
    METRICS_RESPONSE=$(curl -s -u "$SONAR_TOKEN:" "$SONAR_HOST/api/measures/component?component=$TEST_PROJECT_KEY&metricKeys=bugs,vulnerabilities,code_smells,coverage,duplicated_lines_density")
else
    METRICS_RESPONSE=$(curl -s -u "admin:admin" "$SONAR_HOST/api/measures/component?component=$TEST_PROJECT_KEY&metricKeys=bugs,vulnerabilities,code_smells,coverage,duplicated_lines_density")
fi

if [ $? -eq 0 ] && [ "$METRICS_RESPONSE" != "" ]; then
    echo "$METRICS_RESPONSE" > test-results/sonarqube/metrics.json
    
    # Extraire les métriques
    BUGS=$(echo "$METRICS_RESPONSE" | jq -r '.component.measures[] | select(.metric=="bugs") | .value' 2>/dev/null || echo "N/A")
    VULNERABILITIES=$(echo "$METRICS_RESPONSE" | jq -r '.component.measures[] | select(.metric=="vulnerabilities") | .value' 2>/dev/null || echo "N/A")
    CODE_SMELLS=$(echo "$METRICS_RESPONSE" | jq -r '.component.measures[] | select(.metric=="code_smells") | .value' 2>/dev/null || echo "N/A")
    
    echo "Bugs détectés: $BUGS"
    echo "Vulnérabilités détectées: $VULNERABILITIES"
    echo "Code Smells détectés: $CODE_SMELLS"
    
    print_result 0 "Récupération des métriques"
else
    print_result 1 "Récupération des métriques"
    BUGS="N/A"
    VULNERABILITIES="N/A"
    CODE_SMELLS="N/A"
fi

echo -e "\n${BLUE}🎯 Test 6: Vérification Quality Gate${NC}"

# Vérifier le statut de la Quality Gate
if [ -n "$SONAR_TOKEN" ]; then
    QG_RESPONSE=$(curl -s -u "$SONAR_TOKEN:" "$SONAR_HOST/api/qualitygates/project_status?projectKey=$TEST_PROJECT_KEY")
else
    QG_RESPONSE=$(curl -s -u "admin:admin" "$SONAR_HOST/api/qualitygates/project_status?projectKey=$TEST_PROJECT_KEY")
fi

if [ $? -eq 0 ] && [ "$QG_RESPONSE" != "" ]; then
    echo "$QG_RESPONSE" > test-results/sonarqube/quality-gate.json
    
    QG_STATUS=$(echo "$QG_RESPONSE" | jq -r '.projectStatus.status' 2>/dev/null || echo "UNKNOWN")
    echo "Quality Gate Status: $QG_STATUS"
    
    if [ "$QG_STATUS" = "OK" ]; then
        print_result 0 "Quality Gate"
    else
        print_result 1 "Quality Gate (attendu pour du code vulnérable)"
    fi
else
    print_result 1 "Vérification Quality Gate"
    QG_STATUS="UNKNOWN"
fi

echo -e "\n${YELLOW}📈 Résumé des tests SonarQube:${NC}"
echo "- Host SonarQube: $SONAR_HOST"
echo "- Projet analysé: $TEST_PROJECT_KEY"
echo "- Bugs détectés: $BUGS"
echo "- Vulnérabilités détectées: $VULNERABILITIES"
echo "- Code Smells détectés: $CODE_SMELLS"
echo "- Quality Gate: $QG_STATUS"
echo "- Rapports générés dans: test-results/sonarqube/"
echo "- Dashboard: $SONAR_HOST/dashboard?id=$TEST_PROJECT_KEY"

echo -e "\n${GREEN}🎯 Tests SonarQube terminés!${NC}"