#!/bin/bash
# generate_html_report.sh - Generate modern HTML report from recon data

# Colors
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

# Check input
if [ $# -ne 1 ]; then
    echo -e "${RED}[ERROR]${RESET} Usage: $0 <target_directory>"
    exit 1
fi

TARGET_DIR="$1"
REPORT_FILE="$TARGET_DIR/report.html"

# Validate required files
SUBDOMAINS_FILE="$TARGET_DIR/subdomains/all_subdomains.txt"
LIVE_FILE="$TARGET_DIR/all_live.txt"
FFUF_FILE="$TARGET_DIR/reports/FFUF.txt"
NUCLEI_FILE="$TARGET_DIR/reports/nuclei-results.txt"

# Check files exist
for FILE in "$SUBDOMAINS_FILE" "$LIVE_FILE" "$FFUF_FILE" "$NUCLEI_FILE"; do
    if [ ! -f "$FILE" ]; then
        echo -e "${RED}[ERROR]${RESET} Required file missing: $FILE"
        exit 1
    fi
done

# HTML Header
cat <<EOF > "$REPORT_FILE"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ReconX Report</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; background: #f4f4f9; color: #333; margin: 20px; }
        h1, h2 { color: #2c3e50; }
        .section { margin-bottom: 30px; }
        pre {
            background: #1e1e2f;
            color: #eee;
            padding: 15px;
            border-radius: 10px;
            overflow-x: auto;
            white-space: pre-wrap;
        }
        .title {
            background: #3498db;
            color: #fff;
            padding: 10px 15px;
            border-radius: 8px;
            display: inline-block;
        }
    </style>
</head>
<body>
    <h1>🛡️ ReconX Report</h1>
EOF

# Function to append section
add_section() {
    local title="$1"
    local file="$2"
    echo "    <div class=\"section\">" >> "$REPORT_FILE"
    echo "        <h2 class=\"title\">$title</h2>" >> "$REPORT_FILE"
    echo "        <pre>$(cat "$file")</pre>" >> "$REPORT_FILE"
    echo "    </div>" >> "$REPORT_FILE"
}

# Add each section
add_section "🌐 All Subdomains" "$SUBDOMAINS_FILE"
add_section "🟢 Live Subdomains" "$LIVE_FILE"
add_section "📁 FFUF Directory Bruteforce Results" "$FFUF_FILE"
add_section "🚨 Nuclei Findings" "$NUCLEI_FILE"

# Footer
cat <<EOF >> "$REPORT_FILE"
    <footer style="margin-top: 50px; font-size: 0.9em; color: #888;">
        <hr>
        <p>Generated on $(date)</p>
    </footer>
</body>
</html>
EOF

# Success message
echo -e "${GREEN}[INFO]${RESET} HTML report saved to: $REPORT_FILE"
echo -e "${GREEN}[INFO]${RESET} Open the report in your browser to view the results."