#!/bin/bash

echo "🚀 Configuration de l'environnement DevSecOps..."

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

# Vérifier les prérequis
echo -e "${BLUE}🔍 Vérification des prérequis...${NC}"

# Docker
if command -v docker &> /dev/null; then
    print_result 0 "Docker installé"
else
    print_result 1 "Docker non installé"
    echo "Veuillez installer Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# Docker Compose
if command -v docker-compose &> /dev/null; then
    print_result 0 "Docker Compose installé"
else
    print_result 1 "Docker Compose non installé"
    echo "Veuillez installer Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

# Make
if command -v make &> /dev/null; then
    print_result 0 "Make installé"
else
    print_result 1 "Make non installé"
    echo "Installation de Make..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get update && sudo apt-get install -y make
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        xcode-select --install
    fi
fi

# Vérifier l'espace disque
echo -e "\n${BLUE}💾 Vérification de l'espace disque...${NC}"
AVAILABLE_SPACE=$(df . | tail -1 | awk '{print $4}')
REQUIRED_SPACE=5000000  # 5GB en KB

if [ "$AVAILABLE_SPACE" -gt "$REQUIRED_SPACE" ]; then
    print_result 0 "Espace disque suffisant ($(($AVAILABLE_SPACE/1024/1024))GB disponible)"
else
    print_result 1 "Espace disque insuffisant ($(($AVAILABLE_SPACE/1024/1024))GB disponible, 5GB requis)"
    echo "Veuillez libérer de l'espace disque"
    exit 1
fi

# Créer les dossiers nécessaires
echo -e "\n${BLUE}📁 Création des dossiers...${NC}"
mkdir -p test-results/{trivy,checkov,sonarqube,workflow-validation}
mkdir -p backups
mkdir -p logs

print_result 0 "Dossiers créés"

# Configurer les permissions
echo -e "\n${BLUE}🔐 Configuration des permissions...${NC}"
chmod +x tests/test-scripts/*.sh
chmod +x scripts/*.sh
chmod +x docker/docker-entrypoint.sh

print_result 0 "Permissions configurées"

# Créer le fichier d'environnement
echo -e "\n${BLUE}⚙️ Configuration de l'environnement...${NC}"
cat > .env << EOF
# Configuration DevSecOps
COMPOSE_PROJECT_NAME=devsecops
NODE_ENV=production

# SonarQube
SONAR_HOST_URL=http://localhost:9000
SONAR_PROJECT_KEY=security-test-project

# Monitoring
PROMETHEUS_PORT=9090
GRAFANA_PORT=3001

# Sécurité
TRIVY_CACHE_DIR=/tmp/trivy-cache
CHECKOV_LOG_LEVEL=INFO

# Développement
DEV_PORT=5173
WATCH_MODE=false
EOF

print_result 0 "Fichier .env créé"

# Vérifier la connectivité réseau
echo -e "\n${BLUE}🌐 Vérification de la connectivité...${NC}"
if curl -s --connect-timeout 5 https://registry-1.docker.io > /dev/null; then
    print_result 0 "Connectivité Docker Hub"
else
    print_result 1 "Problème de connectivité Docker Hub"
    echo "Vérifiez votre connexion internet"
fi

# Nettoyer les anciens conteneurs si ils existent
echo -e "\n${BLUE}🧹 Nettoyage des anciens conteneurs...${NC}"
docker-compose down -v --remove-orphans 2>/dev/null || true
print_result 0 "Nettoyage effectué"

# Télécharger les images de base
echo -e "\n${BLUE}📥 Téléchargement des images Docker...${NC}"
docker pull node:18-alpine
docker pull nginx:alpine
docker pull ubuntu:22.04
docker pull sonarqube:10.3-community
docker pull postgres:15-alpine
docker pull prom/prometheus:latest
docker pull grafana/grafana:latest

print_result 0 "Images téléchargées"

# Créer un script de démarrage rapide
cat > start-devsecops.sh << 'EOF'
#!/bin/bash
echo "🚀 Démarrage rapide DevSecOps..."
make up
echo "✅ Environnement démarré!"
echo "📋 Accès aux services:"
echo "  - Application: http://localhost:3000"
echo "  - SonarQube: http://localhost:9000"
echo "  - Rapports: http://localhost:8080"
echo "  - Grafana: http://localhost:3001"
EOF

chmod +x start-devsecops.sh

# Créer un script d'arrêt
cat > stop-devsecops.sh << 'EOF'
#!/bin/bash
echo "🛑 Arrêt de l'environnement DevSecOps..."
make down
echo "✅ Environnement arrêté!"
EOF

chmod +x stop-devsecops.sh

# Afficher le résumé
echo -e "\n${GREEN}🎉 Configuration terminée avec succès!${NC}"
echo ""
echo -e "${BLUE}📋 Prochaines étapes:${NC}"
echo "  1. Démarrer l'environnement: ${YELLOW}make install${NC}"
echo "  2. Ou démarrage rapide: ${YELLOW}./start-devsecops.sh${NC}"
echo "  3. Exécuter les tests: ${YELLOW}make test${NC}"
echo "  4. Voir l'aide: ${YELLOW}make help${NC}"
echo ""
echo -e "${BLUE}📚 Documentation:${NC}"
echo "  - README.md pour les détails"
echo "  - tests/README.md pour les tests"
echo "  - Makefile pour les commandes"
echo ""
echo -e "${BLUE}🔗 Services après démarrage:${NC}"
echo "  - Application: http://localhost:3000"
echo "  - SonarQube: http://localhost:9000 (admin/admin)"
echo "  - Rapports: http://localhost:8080"
echo "  - Prometheus: http://localhost:9090"
echo "  - Grafana: http://localhost:3001 (admin/admin)"

echo -e "\n${GREEN}✨ Environnement DevSecOps prêt à l'emploi!${NC}"