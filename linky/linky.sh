#!/usr/bin/bash

#A bit of Styling
cat << "EOF"
──╔╗──╔╗
╔╗╠╬═╦╣╠╦╦╗
║╚╣║║║║═╣║║
╚═╩╩╩═╩╩╬╗║
────────╚═╝
EOF
#Initialization, Only on a fresh install
if [[ "$*" == *"-init"* ]] || [[ "$*" == *"--init"* ]] || [[ "$*" == *"init"* ]] ; then
  echo "➼ Initializing linky..."
  echo "➼ Please exit (ctrl + c) if you already did this" 
  echo "➼ Setting up...$(rm -rf /tmp/example.com 2>/dev/null)"
  linky -u https://example5.com -o /tmp/example.com -gh ghp_xyz 
  rm -rf /tmp/example.com 2>/dev/null
  echo ""
  echo "➼ Initialized Successfully"
  exit 0
fi
#Help / Usage
if [[ "$*" == *"-help"* ]] || [[ "$*" == *"--help"* ]] || [[ "$*" == *"help"* ]] ; then
  echo "➼ Usage: linky -u <url> -o /path/to/outputdir -gh <github_token> -h <optional Headers>"
  echo ""
  echo "Extended Help"
  echo "-u,    --url            Specify the URL to scrape (Required)"
  echo "-o,    --output_dir     Specify the directory to save the output files (Required)"
  echo "-gh,   --github_token   Specify a GitHub personal access token (Required if you want to fetch from github)"
  echo "-h,    --headers        Specify additional headers or cookies to use in the HTTP request (optional)"
  echo "-init, --init           Initialize ➼ linky by dry-running it against example.com (Only run on a fresh Install)"
  echo "-up,   --update         Update linky"
  echo ""
  echo "Example Usage: "
  echo 'linky --url https://example.com --output_dir /path/to/outputdir --github_token ghp_xyz --headers "Authorization: Bearer token; Cookie: cookie_value"'
  echo ""
  exit 0
fi
# Update. Github caches take several minutes to reflect globally  
if [[ $# -gt 0 && ( "$*" == *"up"* || "$*" == *"-up"* || "$*" == *"update"* || "$*" == *"--update"* ) ]]; then
  echo "➼ Checking For Updates"
  REMOTE_FILE=$(mktemp)
  curl -s -H "Cache-Control: no-cache" https://raw.githubusercontent.com/Azathothas/BugGPT-Tools/main/linky/linky.sh -o "$REMOTE_FILE"
  if ! diff --brief /usr/local/bin/linky "$REMOTE_FILE" >/dev/null 2>&1; then
    echo "➼ Update Found! Updating .." 
    dos2unix $REMOTE_FILE 
    sudo mv "$REMOTE_FILE" /usr/local/bin/linky && echo "➼ Updated to @latest" 
    sudo chmod +xwr /usr/local/bin/linky
    rm -f "$REMOTE_FILE" 2>/dev/null
  else
    echo "➼ Already UptoDate"
    rm -f "$REMOTE_FILE" 2>/dev/null
    exit 0
  fi
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
    shift 
    shift 
    ;;
    -o|--output_dir)
    if [ -z "$2" ]; then
      echo "Error: Output Directory is missing for option '-o | --output_dir'"
      exit 1
    fi
    outputDir="$2"
    shift 
    shift 
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
    shift 
    shift 
    ;;
    -h|--headers)
    if [ -z "$2" ]; then
      echo "Error: Header / Cookie Values missing for option '-h | --headers'"
      echo "To display help, use 'help | -help | --help'"

      exit 1
    fi
    optionalHeaders="$2"
    shift 
    shift 
    ;;
    -d|--deep) # treat --deep as a flag option
     deep=1
     shift
    ;;
    *)    # unknown option
    echo "Error: Invalid option '$key' , try --help for more information"
    exit 1
    ;;
  esac
done
# Set default values
export url=$url
export outputDir=$outputDir
export githubToken=$githubToken
export optionalHeaders=$optionalHeaders
export deep=$deep
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
    fi
done
#Health Check for Tools
paths=("$HOME/Tools/xnLinkFinder/xnLinkFinder.py" "$HOME/Tools/JSA/./automation.sh" "$HOME/Tools/github-search/github-endpoints.py" "$HOME/Tools/waymore/waymore.py")
for path in "${paths[@]}"; do
    if [ ! -f "$path" ]; then
        echo "➼ Error: $path not found"
        echo "➼ Attempting to Install missing tools under $HOME/Tools $(mkdir -p $HOME/Tools)"        
        #gwen001/github-search
        cd $HOME/Tools && git clone https://github.com/gwen001/github-search && cd $HOME/Tools/github-search && pip3 install -r requirements.txt
        #w9w/JSA
        cd $HOME/Tools && git clone https://github.com/w9w/JSA.git && cd $HOME/Tools/JSA && pip3 install -r requirements.txt
        wget https://raw.githubusercontent.com/mux0x/needs/main/JSA_automation.sh -O $HOME/Tools/JSA/automation.sh
        chmod +x $HOME/Tools/JSA/automation.sh && chmod +x $HOME/Tools/JSA/automation/404_js_wayback.sh
        #xnl-h4ck3r/Waymore
        cd $HOME/Tools && git clone https://github.com/xnl-h4ck3r/waymore.git && cd $HOME/Tools/waymore  && pip3 install -r requirements.txt 
        python3 $HOME/Tools/waymore/setup.py install
        #xnl-h4ck3r/xnLinkFinder 
        cd $HOME/Tools && git clone https://github.com/xnl-h4ck3r/xnLinkFinder.git && cd $HOME/Tools/xnLinkFinder
        sudo python $HOME/Tools/xnLinkFinder/setup.py install        
    fi
done
#Extract domains from urls
function extract_scope-domain_name()
{
  #Extract root domain name 
   domain=$(echo $url | awk -F/ '{print $3}' | awk -F. '{if (NF>2) {print $(NF-1)"."$NF} else {print $0}}')
   echo $scope-domain
}
scope-domain=$(extract_scope-domain_name $url)
function extract_domain_name() 
{
  #Extract full domain name
   domain=$(echo $url | awk -F/ '{print $3}')
   echo $domain
}
domain=$(extract_scope-domain_name $url)

#Start Tools
#Github-Endpoints
echo "➼ Running github-endpoints on: $url" && sleep 3s
rm -rf /tmp/$scope-domain-gh.txt 
python3 $HOME/Tools/github-search/github-endpoints.py -t $githubToken -d $domain | anew /tmp/$scope-domain-gh.txt
cat /tmp/$scope-domain-gh.txt | anew $outputDir/urls.txt

#GoSpider
echo "➼ Running GoSpider on: $url "
if [ -n "$optionalHeaders" ]; then 
  if [ -n "$deep" ]; then
    gospider -s $url --other-source --include-subs --include-other-source --concurrent 50 --depth 5 -H "$optionalHeaders" --quiet | grep -aEo 'https?://[^ ]+' | sed 's/]$//' | anew $outputDir/urls.txt
  else
    gospider -s $url --other-source --include-subs --include-other-source --concurrent 20 -H "$optionalHeaders" --quiet | grep -aEo 'https?://[^ ]+' | sed 's/]$//' |  anew $outputDir/urls.txt
  fi
else
  if [ -n "$deep" ]; then
    gospider -s $url --other-source --include-subs --include-other-source --concurrent 50 --depth 5 --quiet | grep -aEo 'https?://[^ ]+' | sed 's/]$//' | anew $outputDir/urls.txt
  else 
    gospider -s $url --other-source --include-subs --include-other-source --concurrent 20 --quiet | grep -aEo 'https?://[^ ]+' | sed 's/]$//' | anew $outputDir/urls.txt
  fi
fi
clear 

#Hakrawler
echo "➼ Running hakrawler on: $url" && sleep 3s
if [ -n "$optionalHeaders" ]; then 
   if [ -n "$deep" ]; then
   echo $url | hakrawler -d 5 -insecure -t 20 -h "$optionalHeaders" | anew $outputDir/urls.txt
  else
   echo $url | hakrawler -insecure -t 20 -h "$optionalHeaders" | anew $outputDir/urls.txt
  fi
else
   if [ -n "$deep" ]; then
    echo $url | hakrawler -d 5 -insecure -t 20 | anew $outputDir/urls.txt
  else 
   echo $url | hakrawler -insecure -t 20 | anew $outputDir/urls.txt
  fi
fi 

#Katana
rm -rf /tmp/$scope-domain-katana.txt
echo "➼ Running Katana on: $url" && sleep 3s
if [ -n "$optionalHeaders" ]; then 
   if [ -n "$deep" ]; then
    echo $url | katana -d 5 -H "$optionalHeaders" -o /tmp/$scope-domain-katana.txt 
  else 
    echo $url | katana -H "$optionalHeaders" -o /tmp/$scope-domain-katana.txt
  fi
else
   if [ -n "$deep" ]; then
    echo $url | katana -d 5 -o /tmp/$scope-domain-katana.txt
  else
    echo $url | katana -o /tmp/$scope-domain-katana.txt
  fi
fi
cat /tmp/$scope-domain-katana.txt | anew -q $outputDir/urls.txt && clear 

#XnLinkFinder
echo "➼ Running xnLinkFinder on: $url" && sleep 3s
if [ -n "$optionalHeaders" ]; then 
   if [ -n "$deep" ]; then
    python3 $HOME/Tools/xnLinkFinder/xnLinkFinder.py -i $url -H "$optionalHeaders" -sp $url -d 5 -sf .*$scope-domain -v -insecure -o $outputDir/urls.txt -op $outputDir/parameters.txt
  else
    python3 $HOME/Tools/xnLinkFinder/xnLinkFinder.py -i $url -H "$optionalHeaders" -sp $url -sf .*$scope-domain -v -insecure -o $outputDir/urls.txt -op $outputDir/parameters.txt
  fi
else
  if [ -n "$deep" ]; then
    python3 $HOME/Tools/xnLinkFinder/xnLinkFinder.py -i $url -sp $url -d 5 -sf .*$scope-domain -v -insecure -o $outputDir/urls.txt -op $outputDir/parameters.txt
  else
    python3 $HOME/Tools/xnLinkFinder/xnLinkFinder.py -i $url -sp $url -sf .*$scope-domain -v -insecure -o $outputDir/urls.txt -op $outputDir/parameters.txt
  fi
fi
clear 

#Waymore

echo "➼ Running Waybackurls on: $url"
echo $url | waybackurls | anew $outputDir/urls.txt;
echo "➼ Running gau on: $url" && sleep 3s
echo $url | gau --threads 20 | anew $outputDir/urls.txt && clear

#GetJs Links
cat $outputDir/urls.txt | grep -aEi "\.js([?#].*)?$" | anew $outputDir/js.txt
#JSA
echo $url | $HOME/Tools/JSA/./automation.sh $outputDir $githubToken $outputDir/urls.txt 1> $outputDir/JSA.log 2>&1
cat $outputDir/urls.txt| sed '$!N; /^\(.*\)\n\1$/!P; D'| grep -P '\.php|\.asp|\.js|\.jsp|\.jsp' | anew $outputDir/endpoints.txt
cat $outputDir/urls.txt| grep -Po '(?:\?|\&)(?<key>[\w]+)(?:\=|\&?)(?<value>[\w+,.-]*)' | tr -d '?' | tr -d '&' | sed 's/=.*//' | sort -u | uniq | anew $outputDir/parameters.txt

#QOL Changes
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

#Check For Update on Script end
echo ""
REMOTE_FILE=$(mktemp)
curl -s -H "Cache-Control: no-cache" https://raw.githubusercontent.com/Azathothas/BugGPT-Tools/main/linky/linky.sh -o "$REMOTE_FILE"
if ! diff --brief /usr/local/bin/linky "$REMOTE_FILE" >/dev/null 2>&1; then
echo ""
echo "➼ Update Found! updating .. $(linky -up)" 
  else
  rm -f "$REMOTE_FILE" 2>/dev/null
    exit 0
fi