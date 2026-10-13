#!/usr/bin/env bash

REPORT_FILE="network-report.log"
TARGET=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -t|--target) TARGET="$2"; shift ;;
        -h|--help) 
            echo "Usage: $0 -t <adresse_ip_ou_domaine>"
            exit 0 
            ;;
        *) 
            echo "Erreur : Paramètre invalide : $1" >&2
            echo "Usage: $0 -t <adresse_ip_ou_domaine>" >&2
            exit 1 
            ;;
    esac
    shift
done

if [ -z "$TARGET" ]; then
    echo "Erreur : Aucune cible spécifiée." >&2
    echo "Usage: $0 -t <adresse_ip_ou_domaine>" >&2
    exit 1
fi

{
    echo "=== RAPPORT DE DIAGNOSTIC RÉSEAU ==="
    echo "Date : $(date)"
    echo "----------------------------------------"
    
    echo "[1] Interfaces et adresses IP :"
    ip -brief address show
    echo ""

    echo "[2] Passerelle par défaut :"
    ip route | grep default
    echo ""

    echo "[3] Test d'accessibilité vers : $TARGET"
    if ping -c 3 -W 2 "$TARGET" >/dev/null 2>&1; then
        echo "Résultat : SUCCÈS - La cible $TARGET est accessible."
    else
        echo "Résultat : ÉCHEC - La cible $TARGET est inaccessible (délai dépassé ou hôte inconnu)."
    fi
    echo "================================--------"
} | tee "$REPORT_FILE"