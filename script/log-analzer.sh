set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="${TOOLKIT_CONF:-$PROJECT_DIR/config/toolkit.conf}"
REPORT_DIR="reports"
SERVER_NAME="$(hostname)"

if [[ -r "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "Avertissement : configuration introuvable ($CONFIG_FILE), valeurs par défaut utilisées." >&2
fi
if [[ "$REPORT_DIR" != /* ]]; then
    REPORT_DIR="$PROJECT_DIR/$REPORT_DIR"
fi

ERROR_PATTERN='\b(errors?|err|fail(ed|ure)?|crit(ical)?|fatal|emerg|alert)\b'
WARNING_PATTERN='\b(warn(ing)?s?)\b'
MAX_EXAMPLES=5

usage() {
    cat <<EOF
Usage : $(basename "$0") <fichier_journal>

Analyse un fichier journal et génère un rapport dans :
  $REPORT_DIR

Exemple :
  $(basename "$0") tests/sample.log
EOF
}

error_exit() {
    local message="$1"
    local code="$2"
    echo "Erreur : $message" >&2
    exit "$code"
}

if [[ $# -eq 0 ]]; then
    usage >&2
    error_exit "aucun fichier journal fourni." 1
fi

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
fi

if [[ $# -gt 1 ]]; then
    usage >&2
    error_exit "un seul fichier journal attendu ($# paramètres reçus)." 1
fi

LOG_FILE="$1"

if [[ ! -e "$LOG_FILE" ]]; then
    error_exit "le fichier '$LOG_FILE' n'existe pas." 2
fi

if [[ ! -f "$LOG_FILE" ]]; then
    error_exit "'$LOG_FILE' n'est pas un fichier régulier." 2
fi

if [[ ! -r "$LOG_FILE" ]]; then
    error_exit "le fichier '$LOG_FILE' n'est pas lisible (permissions insuffisantes)." 2
fi

total_lines=$(awk 'END { print NR }' "$LOG_FILE")
error_count=$(grep -ciE "$ERROR_PATTERN" "$LOG_FILE")
warning_count=$(grep -ciE "$WARNING_PATTERN" "$LOG_FILE")

if [[ "$total_lines" -gt 0 ]]; then
    error_percent=$(awk -v e="$error_count" -v t="$total_lines" 'BEGIN { printf "%.1f", e * 100 / t }')
    warning_percent=$(awk -v w="$warning_count" -v t="$total_lines" 'BEGIN { printf "%.1f", w * 100 / t }')
else
    error_percent="0.0"
    warning_percent="0.0"
fi

error_examples=$(grep -niE "$ERROR_PATTERN" "$LOG_FILE" | tail -n "$MAX_EXAMPLES")
warning_examples=$(grep -niE "$WARNING_PATTERN" "$LOG_FILE" | tail -n "$MAX_EXAMPLES")

build_summary() {
    echo "=============================================="
    echo " Analyse du journal"
    echo "=============================================="
    echo "Serveur        : $SERVER_NAME"
    echo "Date           : $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Fichier        : $(realpath "$LOG_FILE")"
    echo "----------------------------------------------"
    echo "Lignes totales : $total_lines"
    echo "Erreurs        : $error_count ($error_percent %)"
    echo "Avertissements : $warning_count ($warning_percent %)"
    echo "----------------------------------------------"
    echo "Dernières erreurs (max $MAX_EXAMPLES) :"
    if [[ -n "$error_examples" ]]; then
        echo "$error_examples" | sed 's/^/  ligne /'
    else
        echo "  Aucune erreur détectée."
    fi
    echo
    echo "Derniers avertissements (max $MAX_EXAMPLES) :"
    if [[ -n "$warning_examples" ]]; then
        echo "$warning_examples" | sed 's/^/  ligne /'
    else
        echo "  Aucun avertissement détecté."
    fi
    echo "=============================================="
}

summary="$(build_summary)"
echo "$summary"


if ! mkdir -p "$REPORT_DIR" 2>/dev/null; then
    error_exit "impossible de créer le répertoire de rapports '$REPORT_DIR'." 3
fi

report_file="$REPORT_DIR/log-analyzer_${SERVER_NAME}_$(date '+%Y%m%d_%H%M%S').txt"

if ! echo "$summary" > "$report_file" 2>/dev/null; then
    error_exit "impossible d'écrire le rapport '$report_file'." 3
fi

echo "Rapport enregistré : $report_file"
exit 0