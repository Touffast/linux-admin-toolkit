#!/bin/bash

# Chargement du fichier de configuration (qui contient le répertoire et le nom du serveur)
source config/toolkit.conf

# Définition du fichier de rapport
RAPPORT="$REPERTOIRE_RAPPORTS/monitor_$(date +%F_%H-%M-%S).txt"

echo "=== Rapport de Surveillance Système ===" > "$RAPPORT"
# 1. Afficher le nom du serveur
echo "Serveur : $NOM_SERVEUR" >> "$RAPPORT"
# 2. Afficher la date et l'heure
echo "Date et heure : $(date)" >> "$RAPPORT"
echo "-----------------------------------" >> "$RAPPORT"
# 3. Afficher l'utilisation de la mémoire
echo "--- Utilisation de la Mémoire ---" >> "$RAPPORT"
free -h >> "$RAPPORT"
# 4. Afficher l'utilisation des systèmes de fichiers
echo "--- Systèmes de fichiers ---" >> "$RAPPORT"
df -h >> "$RAPPORT"
# 5. Afficher la charge du système
echo "--- Charge du système ---" >> "$RAPPORT"
uptime >> "$RAPPORT"

echo "Rapport généré avec succès dans : $RAPPORT"