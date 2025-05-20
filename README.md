# ReconX - Advanced Reconnaissance Tool

ReconX is a powerful Bash script designed for cybersecurity professionals and penetration testers to perform reconnaissance on a target domain. It automates subdomain enumeration, live host detection, directory bruteforcing, and vulnerability scanning, with optional HTML report generation for easy result visualization. The tool is highly configurable, supporting parallel execution and various flags to customize the reconnaissance process.

**Features**:
- **Subdomain Enumeration**: Gathers subdomains using multiple tools (`amass`, `subfinder`, `assetfinder`, `crtsh.py`).
- **Live Host Detection**: Identifies live subdomains using `httpx-toolkit`.
- **Directory Bruteforcing**: Performs directory enumeration with `ffuf`.
- **Vulnerability Scanning**: Runs `nuclei` scans for medium, high, and critical vulnerabilities.
- **HTML Reports**: Generates modern, interactive HTML reports with collapsible sections and navigation.
- **Customizable Options**: Supports flags for skipping steps, adding custom subdomains, deduplicating root domains, and more.

## Installation

### Prerequisites
Ensure the following tools are installed and accessible in your `$PATH`:
- `amass` - Active and passive subdomain enumeration
- `subfinder` - Subdomain discovery tool
- `assetfinder` - Subdomain enumeration via public sources
- `httpx-toolkit` - HTTP probe for live host detection
- `ffuf` - Fast web fuzzer for directory bruteforcing
- `nuclei` - Vulnerability scanner
- `python3` - Required for `crtsh.py` (included in the repository)
- `jq` (optional) - For parsing FFUF JSON output in future enhancements

Install dependencies on a Linux system (e.g., Kali Linux or Ubuntu):

```bash
# Install Go-based tools
go install -v github.com/OWASP/Amass/v3/...@latest
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/tomnomnom/assetfinder@latest
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
go install -v github.com/ffuf/ffuf@latest
go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest

# Install Python and jq
sudo apt update
sudo apt install -y python3 jq

# Ensure tools are in PATH
export PATH=$PATH:$HOME/go/bin
```

### Setup
1. Clone the ReconX repository:
   ```bash
   git clone https://github.com/<your-username>/ReconX.git
   cd ReconX
   ```
2. Make scripts executable:
   ```bash
   chmod +x reconx.sh generate_html_report.sh
   ```
3. Place `custom.txt` (wordlist for FFUF) in the repository directory or specify a custom path with `--ffuf-wordlist`.
4. Ensure `crtsh.py` is in the repository directory or update the `sub_enum` function with its path.

## Usage

Run ReconX with the following syntax:

```bash
./reconx.sh <target_directory> <domain> [flags]
```

- `<target_directory>`: Directory to store output files (e.g., `recon`).
- `<domain>`: Target domain (e.g., `paruluniversity.ac.in`).
- `[flags]`: Optional flags to customize execution (see below).

### Flags
#### Subdomain Enumeration
- `--only-subdomains`: Run only subdomain enumeration and exit.
- `--add-subdomains <file>`: Include subdomains from a specified file.
- `--remove-duplicates`: Keep only one subdomain per root domain.
- `--print-subdomains`: Print the subdomain list to the console.

#### Live Host Detection
- Enabled by default using `httpx-toolkit`. Outputs to `<dir>/live_subdomains.txt`.

#### FFUF Bruteforcing
- `--no-ffuf`: Skip FFUF directory bruteforcing.
- `--ffuf-wordlist <path>`: Specify a custom wordlist for FFUF (default: `./custom.txt`).

#### Nuclei Scanning
- `--no-nuclei`: Skip Nuclei vulnerability scanning.
- `--nuclei-templates <dir>`: Use custom Nuclei templates instead of default (medium, high, critical).

#### Other
- `--html-report`: Generate an HTML report using `generate_html_report.sh`.
- `-h, --help`: Display the help message.

### Examples
1. **Subdomain Enumeration Only with HTML Report**:
   ```bash
   ./reconx.sh recon paruluniversity.ac.in --only-subdomains --html-report --print-subdomains
   ```
   - Enumerates subdomains and generates an HTML report.
   - Prints subdomains to the console.
   - Output stored in `recon/subdomains/all_subdomains.txt` and `recon/report.html`.

2. **Full Reconnaissance**:
   ```bash
   ./reconx.sh recon example.com --html-report
   ```
   - Runs subdomain enumeration, live host detection, FFUF, and Nuclei scans.
   - Generates an HTML report.

3. **Custom Wordlist and Templates**:
   ```bash
   ./reconx.sh recon example.com --ffuf-wordlist /path/to/wordlist.txt --nuclei-templates /path/to/templates --html-report
   ```
   - Uses custom FFUF wordlist and Nuclei templates.

### Output Structure
The output is organized in the specified `<target_directory>` (e.g., `recon`):

```
recon/
├── subdomains/
│   ├── all_subdomains.txt    # Combined unique subdomains
│   ├── amass.txt            # Subdomains from Amass
│   ├── subfinder.txt        # Subdomains from Subfinder
│   ├── assetfinder.txt      # Subdomains from Assetfinder
│   ├── crtsh.txt            # Subdomains from crtsh.py
├── ffuf/
│   ├── <domain>.json        # FFUF results per live subdomain
├── reports/
│   ├── ffuf_results.txt     # Consolidated FFUF results (if generated)
│   ├── nuclei-<timestamp>.txt # Nuclei scan results
├── live_subdomains.txt      # Live subdomains from httpx
├── report.html              # HTML report (if --html-report is used)
```

### HTML Report
The `--html-report` flag generates an interactive HTML report (`report.html`) with:
- **Navigation Bar**: Links to sections (Subdomains, Live Subdomains, FFUF Results, Nuclei Findings).
- **Collapsible Sections**: Clickable headers to show/hide results.
- **Responsive Design**: Mobile-friendly layout.
- **Credits**: Acknowledges the author and contributors.

To view, open `report.html` in a web browser.

## Troubleshooting
- **Script Freezes**: Check debug messages (`[DEBUG]`) to identify which tool (e.g., `amass`, `subfinder`) is hanging. Ensure tools are installed and network connectivity is stable.
- **No Subdomains Found**: Verify the domain is valid and tools are configured (e.g., API keys for `amass`).
- **Missing HTML Report**: Ensure `generate_html_report.sh` is executable and at least one input file exists.
- **Tool Errors**: Run tools individually to diagnose issues:
  ```bash
  amass enum -d example.com -silent
  subfinder -d example.com -silent
  ```

## Credits
Written by **Mayank (AIwolfie)**

## License
This project is licensed under the MIT License. See the `LICENSE` file for details.

## Contributing
Contributions are welcome! Please submit a pull request or open an issue on the repository.
