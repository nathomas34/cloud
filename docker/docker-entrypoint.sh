#!/bin/bash

echo "🚀 Démarrage de l'environnement DevSecOps..."

# Fonction pour attendre qu'un service soit prêt
wait_for_service() {
    local service_name=$1
    local url=$2
    local max_attempts=30
    local attempt=1

    echo "⏳ Attente du service $service_name..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$url" > /dev/null 2>&1; then
            echo "✅ $service_name est prêt!"
            return 0
        fi
        
        echo "⏳ Tentative $attempt/$max_attempts pour $service_name..."
        sleep 10
        attempt=$((attempt + 1))
    done
    
    echo "❌ Timeout: $service_name n'est pas accessible après $max_attempts tentatives"
    return 1
}

# Attendre que SonarQube soit prêt
wait_for_service "SonarQube" "http://sonarqube:9000/api/system/status"

# Configurer SonarQube si nécessaire
echo "🔧 Configuration de SonarQube..."

# Créer un projet de test
curl -s -u admin:admin -X POST \
    "http://sonarqube:9000/api/projects/create" \
    -d "name=Security Test Project" \
    -d "project=security-test-project" \
    -d "visibility=public" || echo "Projet déjà existant"

# Générer un token
TOKEN_RESPONSE=$(curl -s -u admin:admin -X POST \
    "http://sonarqube:9000/api/user_tokens/generate" \
    -d "name=devsecops-token")

if [ $? -eq 0 ]; then
    TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.token' 2>/dev/null)
    if [ "$TOKEN" != "null" ] && [ -n "$TOKEN" ]; then
        echo "✅ Token SonarQube généré: $TOKEN"
        echo "SONAR_TOKEN=$TOKEN" > /workspace/.env
    fi
fi

echo "🎯 Environnement DevSecOps prêt!"
echo ""
echo "📋 Services disponibles:"
echo "  - Application principale: http://localhost:3000"
echo "  - SonarQube: http://localhost:9000 (admin/admin)"
echo "  - Rapports de sécurité: http://localhost:8080"
echo "  - Prometheus: http://localhost:9090"
echo "  - Grafana: http://localhost:3001 (admin/admin)"
echo ""
echo "🧪 Pour exécuter les tests de sécurité:"
echo "  docker-compose exec security-scanner /usr/local/bin/run-all-tests.sh"