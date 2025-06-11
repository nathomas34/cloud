# 🧪 Suite de Tests DevSecOps

Cette suite de tests valide le fonctionnement complet du pipeline DevSecOps en testant tous les outils de sécurité avec des fichiers intentionnellement vulnérables.

## 📋 Vue d'ensemble

### 🎯 Objectifs des Tests

- **Validation fonctionnelle** : Vérifier que tous les outils détectent correctement les vulnérabilités
- **Intégration CI/CD** : Tester les workflows GitHub Actions
- **Rapports SARIF** : Valider la génération des rapports pour GitHub Security
- **Couverture complète** : Tester tous les types de vulnérabilités et configurations

### 🛠️ Outils Testés

| Outil | Type | Cibles | Format de Sortie |
|-------|------|--------|------------------|
| **Trivy** | Scanner de vulnérabilités | Dépendances, secrets, Docker | SARIF, JSON, Table |
| **Checkov** | Analyseur IaC | Terraform, K8s, Dockerfile | SARIF, CLI, JSON |
| **SonarQube** | Qualité du code | Code source, tests | Dashboard Web |

## 📁 Structure des Tests

```
tests/
├── vulnerable-files/          # Fichiers avec vulnérabilités intentionnelles
│   ├── package.json          # Dépendances NPM vulnérables
│   ├── requirements.txt      # Dépendances Python vulnérables
│   ├── Dockerfile           # Configuration Docker non sécurisée
│   ├── secrets.env          # Secrets exposés
│   ├── terraform/           # Infrastructure Terraform vulnérable
│   ├── kubernetes/          # Manifests K8s non sécurisés
│   └── src/                 # Code source vulnérable
│       ├── app.js           # Application Node.js vulnérable
│       └── app.py           # Application Python vulnérable
├── test-scripts/             # Scripts d'exécution des tests
│   ├── run-trivy-tests.sh   # Tests Trivy
│   ├── run-checkov-tests.sh # Tests Checkov
│   ├── run-sonarqube-tests.sh # Tests SonarQube
│   ├── run-all-tests.sh     # Exécution complète
│   └── validate-github-workflow.sh # Validation workflows
└── README.md                # Cette documentation
```

## 🚀 Exécution des Tests

### Prérequis

```bash
# Installation des outils (Ubuntu/Debian)
sudo apt update

# Trivy
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb stable main | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt update && sudo apt install trivy -y

# Checkov
pip install checkov

# SonarQube (Docker)
docker run -d --name sonarqube -p 9000:9000 sonarqube:latest
```

### Exécution Complète

```bash
# Rendre les scripts exécutables
chmod +x tests/test-scripts/*.sh

# Exécuter tous les tests
./tests/test-scripts/run-all-tests.sh
```

### Tests Individuels

```bash
# Tests Trivy uniquement
./tests/test-scripts/run-trivy-tests.sh

# Tests Checkov uniquement
./tests/test-scripts/run-checkov-tests.sh

# Tests SonarQube uniquement
./tests/test-scripts/run-sonarqube-tests.sh

# Validation des workflows GitHub Actions
./tests/test-scripts/validate-github-workflow.sh
```

## 🔍 Détails des Tests

### Tests Trivy 🛡️

#### Vulnérabilités de Dépendances
- **NPM** : `package.json` avec dépendances vulnérables (Express 4.16.0, Lodash 4.17.4, etc.)
- **Python** : `requirements.txt` avec packages vulnérables (Django 2.0.1, Flask 1.0.0, etc.)

#### Détection de Secrets
- Clés AWS exposées
- Tokens API en dur
- Mots de passe dans les variables d'environnement
- Clés privées SSH/TLS

#### Configuration Docker
- Utilisation de l'utilisateur root
- Absence de HEALTHCHECK
- Exposition de ports non sécurisés
- Images avec tags `latest`

**Résultats attendus :**
- 15+ vulnérabilités critiques/hautes dans les dépendances
- 10+ secrets détectés
- 5+ problèmes de configuration Docker

### Tests Checkov ⚙️

#### Infrastructure Terraform
- Buckets S3 publiquement accessibles
- Instances EC2 sans paires de clés
- Groupes de sécurité ouverts (0.0.0.0/0)
- Bases de données RDS non chiffrées
- Mots de passe codés en dur

#### Configuration Kubernetes
- Conteneurs privilégiés
- Montage du système de fichiers hôte
- Absence de limites de ressources
- Services exposés publiquement
- Secrets en dur dans les manifests

**Résultats attendus :**
- 20+ contrôles échoués pour Terraform
- 10+ problèmes de sécurité Kubernetes
- 5+ secrets détectés

### Tests SonarQube 📊

#### Code JavaScript (app.js)
- Injection SQL potentielle
- Vulnérabilités XSS
- Secrets codés en dur
- Utilisation d'`eval()` non sécurisée
- Exposition d'informations sensibles

#### Code Python (app.py)
- Injection SQL directe
- Vulnérabilités XSS
- Injection de commandes
- Désérialisation non sécurisée
- Configuration debug en production

**Résultats attendus :**
- 10+ vulnérabilités de sécurité
- 20+ bugs potentiels
- 30+ code smells
- Quality Gate en échec

## 📊 Rapports Générés

### Structure des Résultats

```
test-results/
├── trivy/
│   ├── vulnerabilities-npm.txt
│   ├── vulnerabilities-python.txt
│   ├── secrets.txt
│   ├── dockerfile-misconfigs.txt
│   └── trivy-results.sarif
├── checkov/
│   ├── terraform-results.txt
│   ├── dockerfile-results.txt
│   ├── kubernetes-results.txt
│   ├── secrets-results.txt
│   └── checkov-results.sarif
├── sonarqube/
│   ├── analysis-log.txt
│   ├── metrics.json
│   └── quality-gate.json
├── workflow-validation/
│   ├── actions-used.txt
│   ├── validation-report.md
│   └── simulation-log.txt
└── consolidated-report.md
```

### Rapport Consolidé

Le fichier `test-results/consolidated-report.md` contient :
- Résumé exécutif de tous les tests
- Statistiques détaillées par outil
- Liste des vulnérabilités détectées
- Recommandations de correction
- Liens vers les dashboards

## 🎯 Utilisation en CI/CD

### GitHub Actions

Les tests peuvent être intégrés dans GitHub Actions :

```yaml
- name: Run Security Tests
  run: |
    chmod +x tests/test-scripts/run-all-tests.sh
    ./tests/test-scripts/run-all-tests.sh

- name: Upload Test Results
  uses: actions/upload-artifact@v4
  with:
    name: security-test-results
    path: test-results/
```

### Validation Continue

```bash
# Exécution quotidienne pour validation
crontab -e
# Ajouter : 0 2 * * * /path/to/project/tests/test-scripts/run-all-tests.sh
```

## 🔧 Configuration

### Variables d'Environnement

```bash
# SonarQube
export SONAR_HOST_URL="http://localhost:9000"
export SONAR_TOKEN="your-sonar-token"

# Optionnel : Configuration des seuils
export TRIVY_SEVERITY="CRITICAL,HIGH,MEDIUM"
export CHECKOV_SOFT_FAIL="true"
```

### Personnalisation

Les scripts peuvent être personnalisés en modifiant :
- Les seuils de sévérité
- Les formats de sortie
- Les exclusions de fichiers
- Les métriques SonarQube

## 🎓 Apprentissage

### Vulnérabilités Couvertes

| Type | Exemples | Outils de Détection |
|------|----------|-------------------|
| **Dépendances** | CVE dans NPM/Python | Trivy |
| **Secrets** | API keys, mots de passe | Trivy, Checkov |
| **IaC** | Configurations AWS/K8s | Checkov |
| **Code** | SQL injection, XSS | SonarQube |
| **Docker** | Privilèges, utilisateurs | Trivy, Checkov |

### Bonnes Pratiques Démontrées

1. **Shift-Left Security** : Détection précoce des vulnérabilités
2. **Automatisation** : Intégration dans les pipelines CI/CD
3. **Rapports standardisés** : Format SARIF pour l'interopérabilité
4. **Couverture complète** : Tous les aspects de la sécurité applicative

## 🆘 Dépannage

### Problèmes Courants

#### SonarQube non accessible
```bash
# Vérifier le statut
docker ps | grep sonarqube

# Redémarrer si nécessaire
docker restart sonarqube

# Attendre le démarrage complet
curl -s http://localhost:9000/api/system/status
```

#### Permissions des scripts
```bash
# Rendre tous les scripts exécutables
find tests/test-scripts/ -name "*.sh" -exec chmod +x {} \;
```

#### Outils manquants
```bash
# Vérifier les installations
trivy --version
checkov --version
sonar-scanner --version
```

## 📚 Ressources

- [Documentation Trivy](https://aquasecurity.github.io/trivy/)
- [Documentation Checkov](https://www.checkov.io/)
- [Documentation SonarQube](https://docs.sonarqube.org/)
- [Format SARIF](https://sarifweb.azurewebsites.net/)
- [GitHub Code Scanning](https://docs.github.com/en/code-security/code-scanning)

---

**🎯 Cette suite de tests démontre une approche complète et professionnelle de la sécurité DevSecOps, couvrant tous les aspects de la sécurité applicative moderne.**