#!/bin/bash

# ──────────────────────────────────────────────────────────────
# ⚙️  QuickRecon - Advanced Recon Script
# Author: Mayank (AIwolfie)
# Description: Enumerates subdomains, finds live hosts, bruteforces directories, and runs Nuclei scans with optional flags and parallelism.
# Version: 1.0.0
# ──────────────────────────────────────────────────────────────

# Color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
RESET="\033[0m"

# Banner
banner() {
  echo -e "${BLUE}"
  echo"░▒▓███████▓▒░░▒▓████████▓▒░▒▓██████▓▒░ ░▒▓██████▓▒░░▒▓███████▓▒░░▒▓█▓▒░░▒▓█▓▒░" 
  echo"░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░" 
  echo"░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░     ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░" 
  echo"░▒▓███████▓▒░░▒▓██████▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░ "  
  echo"░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░     ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░" 
  echo"░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░" 
  echo"░▒▓█▓▒░░▒▓█▓▒░▒▓████████▓▒░▒▓██████▓▒░ ░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░" 
  echo -e "${RESET}"
}

# Logging function
log() {
  echo -e "[$(date +"%T")] $1"
}

error() {
  echo -e "${RED}[ERROR]${RESET} $1" >&2
  exit 1
}

info() {
  echo -e "${GREEN}[INFO]${RESET} $1"
}

warning() {
  echo -e "${YELLOW}[WARN]${RESET} $1"
}

usage() {
  echo -e "\n${YELLOW}USAGE:${RESET} $0 <target_dir> <domain> [flags]"
  echo -e "\n${YELLOW}SUBDOMAIN ENUMERATION FLAGS:${RESET}"
  echo "  --only-subdomains           Run only subdomain enumeration"
  echo "  --add-subdomains <file>     Add subdomains from another file"
  echo "  --remove-duplicates         Keep only one subdomain per root domain"

  echo -e "\n${YELLOW}LIVE HOST DETECTION:${RESET}"
  echo "  (Default: httpx-toolkit, outputs to <dir>/live_subdomains.txt)"

  echo -e "\n${YELLOW}FFUF BRUTEFORCING FLAGS:${RESET}"
  echo "  --no-ffuf                   Skip FFUF scan"
  echo "  --ffuf-wordlist <path>      Custom wordlist for FFUF"

  echo -e "\n${YELLOW}NUCLEI SCANNING FLAGS:${RESET}"
  echo "  --no-nuclei                 Skip nuclei scan"
  echo "  --nuclei-templates <dir>    Use custom nuclei templates"

  echo -e "\n${YELLOW}OTHER FLAGS:${RESET}"
  echo "  --html-report               Generate HTML report (requires generate_html_report.sh)"
  echo "  -h, --help                  Show this help message"
  exit 0
}

# Defaults
ADD_FILE=""
ONLY_SUBS=false
NO_FFUF=false
NO_NUCLEI=false
WORDLIST="$(dirname "$0")/custom.txt"
TEMPLATES="default"
REMOVE_DUPLICATES=false
HTML_REPORT=false

# Arg parsing
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help) usage ;;
    --only-subdomains) ONLY_SUBS=true; shift ;;
    --add-subdomains) ADD_FILE="$2"; shift 2 ;;
    --no-ffuf) NO_FFUF=true; shift ;;
    --ffuf-wordlist) WORDLIST="$2"; shift 2 ;;
    --no-nuclei) NO_NUCLEI=true; shift ;;
    --nuclei-templates) TEMPLATES="$2"; shift 2 ;;
    --remove-duplicates) REMOVE_DUPLICATES=true; shift ;;
    --html-report) GENERATE_HTML=true; shift ;;
    *) POSITIONAL+=("$1"); shift ;;
  esac
done

set -- "${POSITIONAL[@]}"
[ $# -lt 2 ] && usage

DIR="$1"
DOMAIN="$2"
mkdir -p "$DIR/subdomains"
SUBDIR="$DIR/subdomains"
LIVEFILE="$DIR/live_subdomains.txt"
FFUFDIR="$DIR/ffuf"
REPORTS="$DIR/reports"
mkdir -p "$FFUFDIR" "$REPORTS"

banner
info "📁 Target Directory: $DIR"
info "🌐 Target Domain: $DOMAIN"

start_timer() {
  date +%s
}

end_timer() {
  local end=$(date +%s)
  echo $((end - $1))
}

# ────────────────────────────────────────────────
# 🔍 Subdomain Enumeration (Amass, Subfinder, etc)
# ────────────────────────────────────────────────
sub_enum() {
  info "🚀 Enumerating subdomains"
  local t1=$(start_timer)
  amass enum -d "$DOMAIN" -silent -o "$SUBDIR/amass.txt" &
  subfinder -d "$DOMAIN" -silent -o "$SUBDIR/subfinder.txt" &
  assetfinder --subs-only "$DOMAIN" > "$SUBDIR/assetfinder.txt" &
  python3 crtsh.py -d "$DOMAIN" -o "$SUBDIR/crtsh.txt" >/dev/null 2>&1 &
  wait

  cat "$SUBDIR"/*.txt > "$SUBDIR/temp_all.txt"
  if [[ -n "$ADD_FILE" && -f "$ADD_FILE" ]]; then
    cat "$ADD_FILE" >> "$SUBDIR/temp_all.txt"
  fi
  sort -u "$SUBDIR/temp_all.txt" > "$SUBDIR/all_subdomains.txt"
  rm "$SUBDIR/temp_all.txt"

  COUNT=$(wc -l < "$SUBDIR/all_subdomains.txt")
  info "✅ Total unique subdomains: $COUNT"

  if [[ "$REMOVE_DUPLICATES" = true ]]; then
    info "🧹 Removing duplicate root domains"
    awk -F. '{n=NF; if (n >= 2) print $(n-1)"."$n;}' "$SUBDIR/all_subdomains.txt" | sort -u > "$SUBDIR/filtered.txt"
    grep -Ff "$SUBDIR/filtered.txt" "$SUBDIR/all_subdomains.txt" | sort -u > "$SUBDIR/temp.txt"
    mv "$SUBDIR/temp.txt" "$SUBDIR/all_subdomains.txt"
    rm "$SUBDIR/filtered.txt"
    info "✅ Deduplicated subdomains: $(wc -l < "$SUBDIR/all_subdomains.txt")"
  fi
  local t2=$(end_timer $t1)
  info "⏱️ Subdomain enumeration finished in ${t2}s"
}

# ─────────────────────────────
# 🌐 Live Subdomain Check
# ─────────────────────────────
live_check() {
  info "🌐 Checking for live subdomains"
  local t1=$(start_timer)
  httpx-toolkit -l "$SUBDIR/all_subdomains.txt" -silent -o "$LIVEFILE"
  COUNT=$(wc -l < "$LIVEFILE")
  info "✅ Live subdomains found: $COUNT"
  local t2=$(end_timer $t1)
  info "⏱️ Live check finished in ${t2}s"
}

# ─────────────────────────────
# 🔍 FFUF Bruteforce
# ─────────────────────────────
run_ffuf() {
  info "📁 Running FFUF"
  local t1=$(start_timer)
  if [[ ! -f "$WORDLIST" ]]; then
    warning "⚠️ Wordlist $WORDLIST not found. Skipping FFUF."
    return
  fi
  while read -r url; do
    domain=$(echo "$url" | sed 's/https\?:\/\///')
    ffuf -u "$url/FUZZ" -w "$WORDLIST" -mc 200 -c -ac -t 40 \
      -o "$FFUFDIR/${domain//\//_}.json" -of json >/dev/null 2>&1 &
  done < "$LIVEFILE"
  wait
  local t2=$(end_timer $t1)
  info "⏱️ FFUF completed in ${t2}s"
}

# ─────────────────────────────
# 🛡️  Nuclei Scan
# ─────────────────────────────
run_nuclei() {
  info "🛡️ Running nuclei scan"
  local t1=$(start_timer)
  OUT="$REPORTS/nuclei-$(date +%s).txt"
  if [[ "$TEMPLATES" == "default" ]]; then
    nuclei -l "$LIVEFILE" -severity medium,high,critical -o "$OUT" >/dev/null 2>&1
  else
    nuclei -l "$LIVEFILE" -t "$TEMPLATES" -o "$OUT" >/dev/null 2>&1
  fi
  if [[ -s "$OUT" ]]; then
    info "✅ Vulnerabilities found: $(wc -l < "$OUT")"
  else
    info "✅ No vulnerabilities found"
  fi
  local t2=$(end_timer $t1)
  info "⏱️ Nuclei finished in ${t2}s"
}

# ─────────────────────────────
# 🚀 Run all steps
# ─────────────────────────────
sub_enum &
wait
$ONLY_SUBS && exit 0

live_check &
wait
[[ "$NO_FFUF" == false ]] && run_ffuf &
[[ "$NO_NUCLEI" == false ]] && run_nuclei &
wait

# ─────────────────────────────
# 📄 Generate HTML Report
# ─────────────────────────────
if [[ "$GENERATE_HTML" == true ]]; then
  info "📄 Generating HTML report"
  SCRIPT_DIR="$(dirname "$0")"
  chmod +x "$SCRIPT_DIR/generate_html_report.sh"
  bash "$SCRIPT_DIR/generate_html_report.sh" "$DIR"
  info "📁 Report generated at: $DIR/report.html"
fi

info "🎉 Recon complete. Check the $DIR directory for results."
exit 0
