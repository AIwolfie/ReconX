#!/bin/bash
# generate_html_report.sh - Generate modern HTML report from recon data with modular UI
# Author: Mayank (AIwolfie)
# Credits: Written by Mayank (AIwolfie)

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
FFUF_FILE="$TARGET_DIR/reports/ffuf_results.txt"  # Updated path
NUCLEI_FILE="$TARGET_DIR/reports/nuclei-results.txt"

# Check if at least one file exists
if [ ! -f "$SUBDOMAINS_FILE" ] && [ ! -f "$LIVE_FILE" ] && [ ! -f "$FFUF_FILE" ] && [ ! -f "$NUCLEI_FILE" ]; then
    echo -e "${RED}[ERROR]${RESET} No input files found in $TARGET_DIR"
    exit 1
fi

# HTML Header with Modular UI
cat <<EOF > "$REPORT_FILE"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ReconX Report</title>
    <style>
        body {
            font-family: 'Segoe UI', Arial, sans-serif;
            background: #f4f4f9;
            color: #333;
            margin: 0;
            padding: 0;
            line-height: 1.6;
        }
        .container {
            max-width: 1200px;
            margin: 20px auto;
            padding: 0 20px;
        }
        h1 {
            color: #2c3e50;
            text-align: center;
            margin-bottom: 20px;
        }
        .navbar {
            background: #3498db;
            padding: 10px 0;
            margin-bottom: 30px;
            border-radius: 8px;
        }
        .navbar ul {
            list-style: none;
            padding: 0;
            margin: 0;
            display: flex;
            justify-content: center;
            flex-wrap: wrap;
        }
        .navbar li {
            margin: 0 15px;
        }
        .navbar a {
            color: #fff;
            text-decoration: none;
            font-weight: 500;
            padding: 8px 15px;
            border-radius: 5px;
            transition: background 0.3s;
        }
        .navbar a:hover {
            background: #2980b9;
        }
        .section {
            margin-bottom: 30px;
            background: #fff;
            border-radius: 8px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        .section-header {
            background: #3498db;
            color: #fff;
            padding: 15px;
            cursor: pointer;
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-weight: 500;
            border-radius: 8px 8px 0 0;
        }
        .section-header:hover {
            background: #2980b9;
        }
        .section-content {
            padding: 15px;
            display: none;
        }
        .section-content.active {
            display: block;
        }
        pre {
            background: #1e1e2f;
            color: #eee;
            padding: 15px;
            border-radius: 6px;
            overflow-x: auto;
            white-space: pre-wrap;
            margin: 0;
            font-size: 0.9em;
        }
        .no-data {
            color: #888;
            font-style: italic;
        }
        footer {
            margin-top: 50px;
            text-align: center;
            color: #888;
            font-size: 0.9em;
            border-top: 1px solid #ddd;
            padding-top: 20px;
        }
        @media (max-width: 600px) {
            .navbar ul {
                flex-direction: column;
                align-items: center;
            }
            .navbar li {
                margin: 10px 0;
            }
        }
    </style>
    <script>
        document.addEventListener('DOMContentLoaded', () => {
            document.querySelectorAll('.section-header').forEach(header => {
                header.addEventListener('click', () => {
                    const content = header.nextElementSibling;
                    content.classList.toggle('active');
                });
            });
        });
    </script>
</head>
<body>
    <div class="container">
        <h1>🛡️ ReconX Report</h1>
        <nav class="navbar">
            <ul>
EOF

# Add navigation links for available sections
NAV_ITEMS=""
if [ -f "$SUBDOMAINS_FILE" ]; then
    NAV_ITEMS="$NAV_ITEMS<li><a href=\"#subdomains\">All Subdomains</a></li>"
fi
if [ -f "$LIVE_FILE" ]; then
    NAV_ITEMS="$NAV_ITEMS<li><a href=\"#live-subdomains\">Live Subdomains</a></li>"
fi
if [ -f "$FFUF_FILE" ]; then
    NAV_ITEMS="$NAV_ITEMS<li><a href=\"#ffuf-results\">FFUF Results</a></li>"
fi
if [ -f "$NUCLEI_FILE" ]; then
    NAV_ITEMS="$NAV_ITEMS<li><a href=\"#nuclei-findings\">Nuclei Findings</a></li>"
fi

echo "                $NAV_ITEMS" >> "$REPORT_FILE"
echo "            </ul>" >> "$REPORT_FILE"
echo "        </nav>" >> "$REPORT_FILE"

# Function to append section
add_section() {
    local title="$1"
    local file="$2"
    local id="$3"
    echo "        <div class=\"section\" id=\"$id\">" >> "$REPORT_FILE"
    echo "            <div class=\"section-header\">$title</div>" >> "$REPORT_FILE"
    echo "            <div class=\"section-content\">" >> "$REPORT_FILE"
    if [ -f "$file" ]; then
        echo "                <pre>$(cat "$file")</pre>" >> "$REPORT_FILE"
    else
        echo "                <pre class=\"no-data\">No data available</pre>" >> "$REPORT_FILE"
    fi
    echo "            </div>" >> "$REPORT_FILE"
    echo "        </div>" >> "$REPORT_FILE"
}

# Add each section if the file exists
[ -f "$SUBDOMAINS_FILE" ] && add_section "🌐 All Subdomains" "$SUBDOMAINS_FILE" "subdomains"
[ -f "$LIVE_FILE" ] && add_section "🟢 Live Subdomains" "$LIVE_FILE" "live-subdomains"
[ -f "$FFUF_FILE" ] && add_section "📁 FFUF Directory Bruteforce Results" "$FFUF_FILE" "ffuf-results"
[ -f "$NUCLEI_FILE" ] && add_section "🚨 Nuclei Findings" "$NUCLEI_FILE" "nuclei-findings"

# Footer with credits
cat <<EOF >> "$REPORT_FILE"
        <footer>
            <p>Generated on $(date)</p>
            <p>Written by Mayank (AIwolfie)</p>
        </footer>
    </div>
</body>
</html>
EOF

# Success message
echo -e "${GREEN}[INFO]${RESET} HTML report saved to: $REPORT_FILE"
echo -e "${GREEN}[INFO]${RESET} Open the report in your browser to view the results."