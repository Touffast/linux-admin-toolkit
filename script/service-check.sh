#!/bin/bash
# =============================================================================
# service-check.sh
# Vérifie l'état d'un ou plusieurs services systemd (existence, actif/inactif)
# et enregistre les résultats dans un rapport.
#
# Le script NE démarre et N'arrête JAMAIS de service : il est en lecture seule.
#
# Usage :
#   ./service-check.sh nom_service [nom_service2 ...]
#   ./service-check.sh            (mode interactif : saisie successive)
# =============================================================================

RAPPORT="${RAPPORT:-service-check-report.txt}"

if ! command -v systemctl >/dev/null 2>&1; then
    echo "Erreur : systemctl est introuvable sur ce système." >&2
    exit 1
fi

# Enregistre une ligne dans le rapport avec horodatage
log_rapport() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" >> "$RAPPORT"
}

# Vérifie un service : retourne 0 (actif), 1 (inactif), 2 (inexistant)
verifier_service() {
    local nom="${1%.service}"

    if [ -z "$nom" ]; then
        echo "Nom de service vide, ignoré."
        return 2
    fi

    # Le service existe-t-il ?
    if ! systemctl list-unit-files --type=service --no-legend "${nom}.service" 2>/dev/null | grep -q "^${nom}.service"; then
        echo "[INEXISTANT] Le service '$nom' n'existe pas sur ce système."
        log_rapport "$nom | INEXISTANT"
        return 2
    fi

    # Est-il actif ou inactif ?
    if systemctl is-active --quiet "$nom"; then
        echo "[ACTIF]      Le service '$nom' est en cours d'exécution."
        log_rapport "$nom | ACTIF"
        return 0
    else
        local etat
        etat=$(systemctl is-active "$nom" 2>/dev/null)
        echo "[INACTIF]    Le service '$nom' n'est pas actif (état : ${etat:-inconnu})."
        log_rapport "$nom | INACTIF (${etat:-inconnu})"
        return 1
    fi
}

total=0; actifs=0; inactifs=0; inexistants=0

traiter() {
    verifier_service "$1"
    case $? in
        0) actifs=$((actifs + 1)) ;;
        1) inactifs=$((inactifs + 1)) ;;
        2) inexistants=$((inexistants + 1)) ;;
    esac
    total=$((total + 1))
}

log_rapport "=== Début de la vérification ==="

if [ $# -gt 0 ]; then
    # Plusieurs services passés en paramètres
    for svc in "$@"; do
        traiter "$svc"
    done
else
    # Mode interactif : vérifications successives
    echo "Mode interactif (laisser vide ou taper 'q' pour quitter)."
    while true; do
        read -r -p "Nom du service : " svc
        if [ -z "$svc" ] || [ "$svc" = "q" ]; then
            break
        fi
        traiter "$svc"
    done
fi

log_rapport "Résumé : $total vérifié(s), $actifs actif(s), $inactifs inactif(s), $inexistants inexistant(s)"
log_rapport "=== Fin de la vérification ==="

echo
echo "Résumé : $total vérifié(s) - $actifs actif(s), $inactifs inactif(s), $inexistants inexistant(s)"
echo "Rapport enregistré dans : $RAPPORT"