#!/usr/bin/env zsh
#!/usr/bin/env bash

#A bit of Styling
cat << "EOF"
──╔╗──╔╗
╔╗╠╬═╦╣╠╦╦╗
║╚╣║║║║═╣║║
╚═╩╩╩═╩╩╬╗║
────────╚═╝
EOF
#Help / Usage
if [[ "$*" == *"-help"* ]] || [[ "$*" == *"--help"* ]] || [[ "$*" == *"help"* ]] ; then
  echo "Usage: linky -u <url> -o /path/to/outputdir -gh <github_token> -h <optional Headers>"
  echo ""
  echo "Extended Help"
  echo "-u,  --url            Specify the URL to scrape (Required)"
  echo "-o,  --output_dir     Specify the directory to save the output files (Required)"
  echo "-gh, --github_token   Specify a GitHub personal access token (Required if you want to fetch from github)"
  echo "-h,  --headers        Specify additional headers or cookies to use in the HTTP request (optional)"
  echo "-up, --update         Update linky"
  echo ""
  echo "Example Usage:"
  echo 'linky --url https://example.com --output_dir /path/to/outputdir --github_token ghp_xyz --headers "Authorization: Bearer token; Cookie: cookie_value"'
  echo ""
  exit 0
fi
#Update
if [[ "$*" == *"-up"* ]] || [[ "$*" == *"--update"* ]]; then
  sudo rm -rf /usr/local/bin/linky && sudo wget https://raw.githubusercontent.com/Azathothas/BugGPT-Tools/main/linky/linky.sh -O /usr/local/bin/linky
  sudo chmod +xwr /usr/local/bin/linky
  exit 0
fi
# Parse command line options
while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
    -u|--url)
    if [ -z "$2" ]; then
      echo "Error: URL is missing for option '-u | --url'"
      exit 1
    fi
    url="$2"
    shift # past argument
    shift # past value
    ;;
    -o|--output_dir)
    if [ -z "$2" ]; then
      echo "Error: Output Directory is missing for option '-o | --output_dir'"
      exit 1
    fi
    outputDir="$2"
    shift # past argument
    shift # past value
    if [ -d "$outputDir" ]; then
        find $outputDir -type f -size 0 -delete 
        if [ -z "$(ls -A $outputDir)" ]; then
        rm -r $outputDir
        fi
    fi
    # Check if directory already exists
    if [ -d "$outputDir" ]; then
      echo "Directory $outputDir already exists. Supply another for '-o | --output_dir'"
      exit 1
    fi
    # Create directory
    mkdir -p "$outputDir"
    echo "➼ $outputDir created successfully"
    ;;
    -gh|--github_token)
    if [ -z "$2" ]; then
      echo "Error: Github Tokens not specified for option '-gh | --github_token'"
      exit 1
    fi
    githubToken="$2"
    shift # past argument
    shift # past value
    ;;
    -h|--headers)
    if [ -z "$2" ]; then
      echo "Error: Header / Cookie Values missing for option '-h | --headers'"
      echo "To display help, use 'help | -help | --help'"

      exit 1
    fi
    optionalHeaders="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    echo "Error: Invalid option '$key'"
    exit 1
    ;;
  esac
done
# Set default values
export url=$url
export outputDir=$outputDir
export githubToken=$githubToken
export optionalHeaders=$optionalHeaders
#Recheck Values
echo "url: $url"
echo "outputDir: $outputDir"
echo "githubToken: $githubToken"
echo "optionalHeaders: $optionalHeaders"
echo
#Setup Vars
originalDir=$(pwd)
# Check if parallel and chromium-chromedriver are installed, and install them if not
if ! command -v parallel >/dev/null 2>&1; then
    echo "➼ parallel is not installed. Installing..."
    sudo apt-get update && sudo apt-get install parallel -y
fi
if ! command -v chromium >/dev/null 2>&1; then
    echo "➼ chromium-chromedriver is not installed. Installing..."
    sudo apt-get update && sudo apt-get install chromium chromium-chromedriver chromium-common chromium-driver -y
fi
#Health Check for binaries
binaries=("anew" "gau" "gospider" "hakrawler" "katana" "subjs" "waybackurls")
for binary in "${binaries[@]}"; do
    if ! command -v "$binary" &> /dev/null; then
        echo "➼ Error: $binary not found"
        echo "➼ Attempting to Install missing tools"
        go install -v github.com/tomnomnom/anew@latest
        go install -v github.com/lc/gau/v2/cmd/gau@latest
        go install -v github.com/jaeles-project/gospider@latest
        go install -v github.com/hakluke/hakrawler@latest
        go install -v github.com/projectdiscovery/katana/cmd/katana@latest
        go install -v github.com/lc/subjs@latest
        go install -v github.com/tomnomnom/waybackurls@latest
        exit 1
    fi
done
#Health Check for Tools
paths=("$HOME/Tools/xnLinkFinder/xnLinkFinder.py" "$HOME/Tools/JSA/./automation.sh" "$HOME/Tools/github-endpoints.py")
for path in "${paths[@]}"; do
    if [ ! -f "$path" ]; then
        echo "➼ Error: $path not found"
        echo "➼ Attempting to Install missing tools under $HOME/Tools"
        #xnl-h4ck3r/xnLinkFinder 
        git clone https://github.com/xnl-h4ck3r/xnLinkFinder $HOME/Tools/xnLinkFinder
        cd $HOME/Tools/xnLinkFinder && sudo python setup.py install
        #gwen001/github-search
        wget https://raw.githubusercontent.com/gwen001/github-search/master/github-endpoints.py -O $HOME/Tools/github-endpoints.py
        #w9w/JSA
        git clone https://github.com/w9w/JSA.git && cd JSA && pip3 install -r requirements.txt
        wget https://raw.githubusercontent.com/mux0x/needs/main/JSA_automation.sh -O $HOME/Tools/JSA/automation.sh
        chmod +x $HOME/Tools/JSA/automation.sh && chmod +x $HOME/Tools/JSA/automation/./404_js_wayback.sh
        exit 1
    fi
done
#Start Tool
function extract_domain_name() {
    # Extract domain name up to the second level
    domain=$(echo $url | awk -F/ '{print $3}' | awk -F. '{if (NF>2) {print $(NF-1)"."$NF} else {print $0}}')
    # Return domain name
    echo $domain
}
domain=$(extract_domain_name $url)
echo "➼ Running Waybackurls on: $url"
echo $url | waybackurls | anew $outputDir/urls.txt;
echo "➼ Running gau on: $url" && sleep 3s
echo $url | gau --threads 20 | anew $outputDir/urls.txt
clear 
rm -rf /tmp/$domain-katana.txt
echo "➼ Running Katana on: $url" && sleep 3s
if [ -n "$optionalHeaders" ]; then 
    echo $url | katana -H "$optionalHeaders" -o /tmp/$domain-katana.txt
else
    echo $url | katana -o /tmp/$domain-katana.txt
fi
cat /tmp/$domain-katana.txt | anew -q $outputDir/urls.txt
clear 
echo "➼ Running hakrawler on: $url" && sleep 3s
if [ -n "$optionalHeaders" ]; then 
    echo $url | hakrawler -insecure -t 20 -h "$optionalHeaders" | anew $outputDir/urls.txt
else
    echo $url | hakrawler -insecure -t 20 | anew $outputDir/urls.txt
fi
clear 
echo "➼ Running GoSpider silently on: $url & Saving Output" && sleep 3s
if [ -n "$optionalHeaders" ]; then 
    gospider -s $url -a -w -r -c 20 -H "$optionalHeaders" | grep -aEo 'https?://[^ ]+' | sed 's/]$//' | sort -u | anew $outputDir/urls.txt
else
    gospider -s $url -a -w -r -c 20 | grep -aEo 'https?://[^ ]+' | sed 's/]$//' | sort -u | anew $outputDir/urls.txt
fi
clear 
echo "➼ Running xnLinkFinder on: $url" && sleep 3s
if [ -n "$optionalHeaders" ]; then 
    python3 $HOME/Tools/xnLinkFinder/xnLinkFinder.py  -i $url -H "$optionalHeaders" -sp $url -d 4 -sf .*$domain -v -o $outputDir/urls.txt -op $outputDir/parameters.txt
else
    python3 $HOME/Tools/xnLinkFinder/xnLinkFinder.py  -i $url -sp $url -d 4 -sf .*$domain -v -o $outputDir/urls.txt -op $outputDir/parameters.txt
fi
clear 
echo "➼ Running github-endpoints on: $url" && sleep 3s
rm -rf /tmp/$domain-gh.txt 
python3 $HOME/Tools/github-endpoints.py -t $githubToken -d $domain | anew /tmp/$domain-gh.txt
cat /tmp/$domain-gh.txt | anew $outputDir/urls.txt
cat $outputDir/urls.txt | grep -aEi "\.js([?#].*)?$" | anew $outputDir/js.txt
echo $url | $HOME/Tools/JSA/./automation.sh $outputDir $githubToken $outputDir/urls.txt 1> $outputDir/JSA.log 2>&1
cat $outputDir/urls.txt| sed '$!N; /^\(.*\)\n\1$/!P; D'| grep -P '\.php|\.asp|\.js|\.jsp|\.jsp' | anew $outputDir/endpoints.txt
cat $outputDir/urls.txt| grep -Po '(?:\?|\&)(?<key>[\w]+)(?:\=|\&?)(?<value>[\w+,.-]*)' | tr -d '?' | tr -d '&' | sed 's/=.*//' | sort -u | uniq | anew $outputDir/parameters.txt
cd $originalDir
echo "➼ All Links Scraped and Saved in: $outputDir"
files=( "$outputDir/js.txt" "$outputDir/parameters.txt" "$outputDir/urls.txt" "$outputDir/endpoints.txt" )
labels=( "JavaScript URLs" "Parameters" "URLs" "Endpoints" )
for i in "${!files[@]}"; do
    if [ -f "${files[i]}" ]; then
        count=$(wc -l < "${files[i]}")
        echo "➼ Total ${labels[i]} (${files[i]}) --> ${count// /}"
    else
        echo "➼ File ${files[i]} not found"
    fi
done