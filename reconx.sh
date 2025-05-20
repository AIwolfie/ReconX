#!/bin/bash

# ──────────────────────────────────────────────────────────────
# ⚙️  QuickRecon - Advanced Recon Script
# Author: Mayank (AIwolfie)
# Description: Enumerates subdomains, finds live hosts, bruteforces directories, and runs Nuclei scans with optional flags and parallelism.
# Version: 1.0.4
# Credits: Written by Mayank (AIwolfie)
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
  echo "░▒▓███████▓▒░░▒▓████████▓▒░▒▓██████▓▒░ ░▒▓██████▓▒░░▒▓███████▓▒░░▒▓█▓▒░░▒▓█▓▒░"
  echo "░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░"
  echo "░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░     ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░"
  echo "░▒▓███████▓▒░░▒▓██████▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░"
  echo "░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░     ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░"
  echo "░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░"
  echo "░▒▓█▓▒░░▒▓█▓▒░▒▓████████▓▒░▒▓██████▓▒░ ░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░"
  echo -e "${RESET}"
}

# Logging functions
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

debug() {
  echo -e "${BLUE}[DEBUG]${RESET} $1"
}

usage() {
  echo -e "\n${YELLOW}USAGE:${RESET} $0 <target_dir> <domain> [flags]"
  echo -e "\n${YELLOW}SUBDOMAIN ENUMERATION FLAGS:${RESET}"
  echo "  --only-subdomains           Run only subdomain enumeration"
  echo "  --add-subdomains <file>     Add subdomains from another file"
  echo "  --remove-duplicates         Keep only one subdomain per root domain"
  echo "  --print-subdomains          Print subdomain list to console"

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
GENERATE_HTML=false
PRINT_SUBDOMAINS=false

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
    --print-subdomains) PRINT_SUBDOMAINS=true; shift ;;
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

  # Run tools with timeout to prevent hanging
  timeout 300 amass enum -d "$DOMAIN" -silent -o "$SUBDIR/amass.txt" && debug "Amass completed" || warning "Amass failed or timed out"
  timeout 300 subfinder -d "$DOMAIN" -silent -o "$SUBDIR/subfinder.txt" && debug "Subfinder completed" || warning "Subfinder failed or timed out"
  timeout 300 assetfinder --subs-only "$DOMAIN" > "$SUBDIR/assetfinder.txt" && debug "Assetfinder completed" || warning "Assetfinder failed or timed out"
  timeout 300 python3 crtsh.py -d "$DOMAIN" -o "$SUBDIR/crtsh.txt" >/dev/null 2>&1 && debug "crtsh.py completed" || warning "crtsh.py failed or timed out"
  wait

  # Check if any output files were created
  if [ ! -f "$SUBDIR/amass.txt" ] && [ ! -f "$SUBDIR/subfinder.txt" ] && [ ! -f "$SUBDIR/assetfinder.txt" ] && [ ! -f "$SUBDIR/crtsh.txt" ]; then
    error "No subdomain files created. Check tool installation and network connectivity."
  fi

  # Count subdomains from each tool
  AMASS_COUNT=$(wc -l < "$SUBDIR/amass.txt" 2>/dev/null || echo 0)
  SUBFINDER_COUNT=$(wc -l < "$SUBDIR/subfinder.txt" 2>/dev/null || echo 0)
  ASSETFINDER_COUNT=$(wc -l < "$SUBDIR/assetfinder.txt" 2>/dev/null || echo 0)
  CRTSH_COUNT=$(wc -l < "$SUBDIR/crtsh.txt" 2>/dev/null || echo 0)
  info "🔢 Subdomains gathered: Amass ($AMASS_COUNT), Subfinder ($SUBFINDER_COUNT), Assetfinder ($ASSETFINDER_COUNT), crtsh ($CRTSH_COUNT)"

  # Combine results
  : > "$SUBDIR/temp_all.txt" # Create empty file to avoid errors if no results
  for file in "$SUBDIR/amass.txt" "$SUBDIR/subfinder.txt" "$SUBDIR/assetfinder.txt" "$SUBDIR/crtsh.txt"; do
    [ -f "$file" ] && cat "$file" >> "$SUBDIR/temp_all.txt"
  done
  if [[ -n "$ADD_FILE" && -f "$ADD_FILE" ]]; then
    cat "$ADD_FILE" >> "$SUBDIR/temp_all.txt"
  fi

  # Check if temp_all.txt is empty
  if [ ! -s "$SUBDIR/temp_all.txt" ]; then
    error "No subdomains found. Check tool output and domain validity."
  fi

  sort -u "$SUBDIR/temp_all.txt" > "$SUBDIR/all_subdomains.txt"
  rm "$SUBDIR/temp_all.txt"

  COUNT=$(wc -l < "$SUBDIR/all_subdomains.txt")
  info "✅ Total unique subdomains: $COUNT"

  # Print subdomains if requested
  if [[ "$PRINT_SUBDOMAINS" = true ]]; then
    info "📜 Printing subdomain list:"
    cat "$SUBDIR/all_subdomains.txt"
  fi

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

info "🎉 Recon complete. Check the $DIR directory for Mujeres
exit 0