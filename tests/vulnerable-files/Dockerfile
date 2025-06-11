FROM node:14

# Vulnérabilité: Utilisation de l'utilisateur root
USER root

# Vulnérabilité: Installation de packages sans vérification
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Vulnérabilité: Copie de tous les fichiers
COPY . /app

WORKDIR /app

# Vulnérabilité: Installation sans --production
RUN npm install

# Vulnérabilité: Exposition de port non sécurisé
EXPOSE 3000

# Vulnérabilité: Pas de HEALTHCHECK
# HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
#   CMD curl -f http://localhost:3000/health || exit 1

# Vulnérabilité: Exécution en tant que root
CMD ["npm", "start"]