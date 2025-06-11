# Makefile pour l'environnement DevSecOps

.PHONY: help build up down logs clean test security-scan setup-sonar

# Variables
COMPOSE_FILE = docker-compose.yml
PROJECT_NAME = devsecops

help: ## Afficher l'aide
	@echo "🛡️ Environnement DevSecOps - Commandes disponibles:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$\' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Construire toutes les images Docker
	@echo "🔨 Construction des images Docker..."
	docker-compose build

up: ## Démarrer tous les services
	@echo "🚀 Démarrage de l'environnement DevSecOps..."
	docker-compose up -d
	@echo "⏳ Attente du démarrage des services..."
	@sleep 30
	@echo "✅ Environnement prêt!"
	@echo ""
	@echo "📋 Services disponibles:"
	@echo "  - Application: http://localhost:3000"
	@echo "  - SonarQube: http://localhost:9000 (admin/admin)"
	@echo "  - Rapports: http://localhost:8080"
	@echo "  - Prometheus: http://localhost:9090"
	@echo "  - Grafana: http://localhost:3001 (admin/admin)"

down: ## Arrêter tous les services
	@echo "🛑 Arrêt de l'environnement DevSecOps..."
	docker-compose down

restart: down up ## Redémarrer tous les services

logs: ## Afficher les logs de tous les services
	docker-compose logs -f

logs-app: ## Afficher les logs de l'application
	docker-compose logs -f devsecops-app

logs-sonar: ## Afficher les logs de SonarQube
	docker-compose logs -f sonarqube

status: ## Afficher le statut des services
	@echo "📊 Statut des services:"
	@docker-compose ps

clean: ## Nettoyer les conteneurs et volumes
	@echo "🧹 Nettoyage de l'environnement..."
	docker-compose down -v --remove-orphans
	docker system prune -f

clean-all: ## Nettoyage complet (images, volumes, réseaux)
	@echo "🧹 Nettoyage complet..."
	docker-compose down -v --remove-orphans --rmi all
	docker system prune -af --volumes

test: ## Exécuter tous les tests de sécurité
	@echo "🧪 Exécution des tests de sécurité..."
	docker-compose exec security-scanner /usr/local/bin/run-all-tests.sh

test-trivy: ## Exécuter uniquement les tests Trivy
	@echo "🛡️ Exécution des tests Trivy..."
	docker-compose exec security-scanner /usr/local/bin/run-trivy-tests.sh

test-checkov: ## Exécuter uniquement les tests Checkov
	@echo "⚙️ Exécution des tests Checkov..."
	docker-compose exec security-scanner /usr/local/bin/run-checkov-tests.sh

test-sonar: ## Exécuter uniquement les tests SonarQube
	@echo "📊 Exécution des tests SonarQube..."
	docker-compose exec security-scanner /usr/local/bin/run-sonarqube-tests.sh

security-scan: ## Lancer un scan de sécurité complet
	@echo "🔍 Scan de sécurité complet..."
	docker-compose exec security-scanner bash -c "cd /workspace && /usr/local/bin/run-all-tests.sh"

setup-sonar: ## Configurer SonarQube avec un projet de test
	@echo "🔧 Configuration de SonarQube..."
	@sleep 5
	@curl -s -u admin:admin -X POST "http://localhost:9000/api/projects/create\" \
		-d "name=Security Test Project\" \
		-d "project=security-test-project\" \
		-d "visibility=public" || echo "Projet déjà existant"
	@echo "✅ SonarQube configuré"

shell-scanner: ## Ouvrir un shell dans le conteneur de scan
	docker-compose exec security-scanner bash

shell-app: ## Ouvrir un shell dans le conteneur de l'application
	docker-compose exec devsecops-app sh

backup: ## Sauvegarder les données
	@echo "💾 Sauvegarde des données..."
	@mkdir -p backups
	@docker run --rm -v $(PROJECT_NAME)_sonarqube_data:/data -v $(PWD)/backups:/backup alpine tar czf /backup/sonarqube-data-$(shell date +%Y%m%d-%H%M%S).tar.gz -C /data .
	@docker run --rm -v $(PROJECT_NAME)_postgres_data:/data -v $(PWD)/backups:/backup alpine tar czf /backup/postgres-data-$(shell date +%Y%m%d-%H%M%S).tar.gz -C /data .
	@echo "✅ Sauvegarde terminée dans ./backups/"

restore: ## Restaurer les données (spécifier BACKUP_FILE=filename)
	@echo "📥 Restauration des données..."
	@if [ -z "$(BACKUP_FILE)" ]; then echo "❌ Veuillez spécifier BACKUP_FILE=filename"; exit 1; fi
	@docker run --rm -v $(PROJECT_NAME)_sonarqube_data:/data -v $(PWD)/backups:/backup alpine tar xzf /backup/$(BACKUP_FILE) -C /data
	@echo "✅ Restauration terminée"

monitor: ## Ouvrir le monitoring dans le navigateur
	@echo "📊 Ouverture du monitoring..."
	@open http://localhost:3001 || xdg-open http://localhost:3001 || echo "Ouvrez http://localhost:3001 dans votre navigateur"

dev: ## Mode développement avec rechargement automatique
	@echo "🔧 Mode développement..."
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

prod: up ## Mode production

install: build up setup-sonar ## Installation complète
	@echo "🎉 Installation terminée!"
	@echo ""
	@echo "🚀 Prochaines étapes:"
	@echo "  1. Visitez http://localhost:3000 pour l'application"
	@echo "  2. Connectez-vous à SonarQube: http://localhost:9000 (admin/admin)"
	@echo "  3. Exécutez les tests: make test"
	@echo "  4. Consultez les rapports: http://localhost:8080"

update: ## Mettre à jour les images Docker
	@echo "🔄 Mise à jour des images..."
	docker-compose pull
	docker-compose build --pull

health: ## Vérifier la santé des services
	@echo "🏥 Vérification de la santé des services..."
	@echo ""
	@echo "Application:"
	@curl -s http://localhost:3000/health || echo "❌ Application non accessible"
	@echo ""
	@echo "SonarQube:"
	@curl -s http://localhost:9000/api/system/status || echo "❌ SonarQube non accessible"
	@echo ""
	@echo "Rapports:"
	@curl -s http://localhost:8080/health || echo "❌ Serveur de rapports non accessible"

demo: install test ## Installation et démonstration complète
	@echo "🎭 Démonstration DevSecOps terminée!"
	@echo "📊 Consultez les résultats sur http://localhost:8080"