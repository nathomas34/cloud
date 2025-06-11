# 🐳 DevSecOps Environment - Guide Docker

Ce guide détaille l'utilisation de l'environnement DevSecOps dockerisé complet.

## 🚀 Démarrage Rapide

### Installation Automatique

```bash
# 1. Configurer l'environnement
chmod +x scripts/setup-environment.sh
./scripts/setup-environment.sh

# 2. Démarrer tous les services
make install

# 3. Exécuter les tests de sécurité
make test
```

### Démarrage Manuel

```bash
# Construire les images
docker-compose build

# Démarrer les services
docker-compose up -d

# Vérifier le statut
docker-compose ps
```

## 🏗️ Architecture Docker

### Services Déployés

| Service | Port | Description | URL |
|---------|------|-------------|-----|
| **devsecops-app** | 3000 | Application React principale | http://localhost:3000 |
| **sonarqube** | 9000 | Plateforme d'analyse de code | http://localhost:9000 |
| **postgres** | 5432 | Base de données SonarQube | - |
| **security-scanner** | - | Conteneur avec outils de sécurité | - |
| **reports-server** | 8080 | Serveur de rapports | http://localhost:8080 |
| **prometheus** | 9090 | Monitoring des métriques | http://localhost:9090 |
| **grafana** | 3001 | Dashboard de monitoring | http://localhost:3001 |

### Réseau Docker

- **Réseau**: `devsecops-network` (172.20.0.0/16)
- **Communication**: Tous les services peuvent communiquer entre eux
- **Isolation**: Réseau isolé du host sauf pour les ports exposés

## 📦 Images Docker

### Application Principale (`Dockerfile`)

```dockerfile
# Multi-stage build
FROM node:18-alpine AS builder  # Build de l'application React
FROM nginx:alpine AS production # Serveur de production
```

**Fonctionnalités:**
- Build optimisé multi-stage
- Serveur Nginx avec configuration sécurisée
- Health checks intégrés
- Compression gzip
- Headers de sécurité

### Scanner de Sécurité (`docker/Dockerfile.scanner`)

```dockerfile
FROM ubuntu:22.04
# Installation de Trivy, Checkov, SonarScanner
```

**Outils inclus:**
- Trivy (scanner de vulnérabilités)
- Checkov (analyseur IaC)
- SonarScanner (client SonarQube)
- Outils supplémentaires (safety, bandit, semgrep)

## 🛠️ Commandes Make

### Commandes Principales

```bash
make help          # Afficher l'aide complète
make install       # Installation complète
make up            # Démarrer les services
make down          # Arrêter les services
make restart       # Redémarrer les services
make status        # Statut des services
make logs          # Logs de tous les services
```

### Tests de Sécurité

```bash
make test          # Tous les tests
make test-trivy    # Tests Trivy uniquement
make test-checkov  # Tests Checkov uniquement
make test-sonar    # Tests SonarQube uniquement
make security-scan # Scan complet
```

### Maintenance

```bash
make clean         # Nettoyer conteneurs et volumes
make clean-all     # Nettoyage complet
make backup        # Sauvegarder les données
make restore       # Restaurer les données
make update        # Mettre à jour les images
make health        # Vérifier la santé des services
```

### Développement

```bash
make dev           # Mode développement
make shell-scanner # Shell dans le conteneur scanner
make shell-app     # Shell dans l'application
```

## 🔧 Configuration

### Variables d'Environnement (`.env`)

```bash
# Configuration principale
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
```

### Personnalisation des Ports

Modifiez `docker-compose.yml` pour changer les ports :

```yaml
services:
  devsecops-app:
    ports:
      - "8000:80"  # Changer le port de l'application
```

## 📊 Monitoring et Observabilité

### Prometheus (Port 9090)

**Métriques collectées:**
- Santé des services
- Métriques applicatives
- Statut des conteneurs

**Configuration:** `docker/prometheus.yml`

### Grafana (Port 3001)

**Accès:** admin/admin

**Dashboards inclus:**
- DevSecOps Security Dashboard
- Métriques des services
- Alertes de sécurité

**Configuration:** `docker/grafana/`

### Health Checks

Tous les services incluent des health checks :

```bash
# Vérifier la santé
docker-compose ps
make health

# Logs des health checks
docker-compose logs | grep health
```

## 🔒 Sécurité

### Configuration Nginx

**Headers de sécurité appliqués:**
```nginx
add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;
add_header X-XSS-Protection "1; mode=block";
add_header Referrer-Policy "strict-origin-when-cross-origin";
add_header Content-Security-Policy "default-src 'self'...";
```

### Utilisateurs Non-Root

- Le scanner utilise un utilisateur `scanner` non-root
- L'application Nginx utilise l'utilisateur nginx par défaut
- Principe du moindre privilège appliqué

### Réseau Isolé

- Réseau Docker dédié
- Communication inter-services sécurisée
- Exposition minimale des ports

## 📁 Volumes et Persistance

### Volumes Nommés

```yaml
volumes:
  sonarqube_data:     # Données SonarQube
  sonarqube_extensions: # Extensions SonarQube
  sonarqube_logs:     # Logs SonarQube
  postgres_data:      # Base de données
  prometheus_data:    # Métriques Prometheus
  grafana_data:       # Configuration Grafana
```

### Volumes Montés

```yaml
volumes:
  - ./tests:/usr/share/nginx/html/tests:ro  # Tests en lecture seule
  - ./test-results:/workspace/test-results  # Résultats des tests
```

## 🧪 Tests et Validation

### Exécution des Tests

```bash
# Dans le conteneur scanner
docker-compose exec security-scanner bash

# Exécuter tous les tests
/usr/local/bin/run-all-tests.sh

# Tests individuels
/usr/local/bin/run-trivy-tests.sh
/usr/local/bin/run-checkov-tests.sh
/usr/local/bin/run-sonarqube-tests.sh
```

### Résultats des Tests

Les résultats sont disponibles :
- **Localement:** `./test-results/`
- **Via web:** http://localhost:8080
- **Dans les logs:** `docker-compose logs security-scanner`

## 🔄 Mode Développement

### Configuration Dev

```bash
# Démarrer en mode développement
make dev

# Ou manuellement
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
```

**Fonctionnalités dev:**
- Hot reload de l'application React
- Volumes montés pour le code source
- Port Vite dev server (5173)
- Logs détaillés

### Debugging

```bash
# Logs en temps réel
make logs

# Logs d'un service spécifique
make logs-app
make logs-sonar

# Shell interactif
make shell-scanner
make shell-app
```

## 💾 Sauvegarde et Restauration

### Sauvegarde Automatique

```bash
# Sauvegarder toutes les données
make backup

# Fichiers créés dans ./backups/
# - sonarqube-data-YYYYMMDD-HHMMSS.tar.gz
# - postgres-data-YYYYMMDD-HHMMSS.tar.gz
```

### Restauration

```bash
# Restaurer depuis une sauvegarde
make restore BACKUP_FILE=sonarqube-data-20241201-143000.tar.gz
```

### Sauvegarde Manuelle

```bash
# Exporter les volumes
docker run --rm -v devsecops_sonarqube_data:/data \
  -v $(pwd)/backups:/backup alpine \
  tar czf /backup/manual-backup.tar.gz -C /data .
```

## 🚨 Dépannage

### Problèmes Courants

#### Services ne démarrent pas

```bash
# Vérifier les logs
make logs

# Vérifier l'espace disque
df -h

# Nettoyer et redémarrer
make clean
make up
```

#### SonarQube ne répond pas

```bash
# Vérifier le statut
curl http://localhost:9000/api/system/status

# Redémarrer SonarQube
docker-compose restart sonarqube

# Vérifier les logs
make logs-sonar
```

#### Tests échouent

```bash
# Vérifier la connectivité
make health

# Exécuter les tests en mode debug
docker-compose exec security-scanner bash
cd /workspace
/usr/local/bin/run-trivy-tests.sh
```

#### Problèmes de permissions

```bash
# Réinitialiser les permissions
chmod +x scripts/*.sh
chmod +x tests/test-scripts/*.sh

# Vérifier les volumes
docker-compose down
docker volume ls
```

### Commandes de Diagnostic

```bash
# Informations système
docker system info
docker system df

# État des conteneurs
docker-compose ps
docker stats

# Réseau
docker network ls
docker network inspect devsecops_devsecops-network

# Volumes
docker volume ls
docker volume inspect devsecops_sonarqube_data
```

## 🔄 Mise à Jour

### Mise à Jour des Images

```bash
# Mettre à jour toutes les images
make update

# Ou manuellement
docker-compose pull
docker-compose build --pull
```

### Mise à Jour de la Configuration

```bash
# Sauvegarder avant mise à jour
make backup

# Arrêter les services
make down

# Mettre à jour le code
git pull

# Reconstruire et redémarrer
make build
make up
```

## 📚 Ressources Supplémentaires

- **Docker Compose Reference:** https://docs.docker.com/compose/
- **Nginx Configuration:** https://nginx.org/en/docs/
- **SonarQube Docker:** https://hub.docker.com/_/sonarqube
- **Prometheus Docker:** https://hub.docker.com/r/prom/prometheus
- **Grafana Docker:** https://hub.docker.com/r/grafana/grafana

---

**🎯 Cet environnement Docker fournit une plateforme DevSecOps complète, portable et prête pour la production.**