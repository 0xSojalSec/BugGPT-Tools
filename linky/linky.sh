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
  echo "Initialized Successfully"
  exit 0
fi
#Help / Usage
if [[ "$*" == *"-help"* ]] || [[ "$*" == *"--help"* ]] || [[ "$*" == *"help"* ]] ; then
  echo "➼ Usage: linky -u <url> -o /path/to/outputdir -gh <github_token> -h <optional Headers>"
  echo ""
  echo "Extended Help"
  echo "-u,     --url            Specify the URL to scrape (Required)"
  echo "-o,     --output_dir     Specify the directory to save the output files (Required)"
  echo "-gh,    --github_token   Specify manually else (Not Required if $HOME/.config/.github_tokens exists)"
  echo "-d,     --deep           Specify if Gospider, Hakrawler, Katana & XnLinkfinder should run with depth 5. (Super Slow)"
  echo "-h,     --headers        Specify additional headers or cookies to use in the HTTP request (optional)"
  echo "-init,  --init           Initialize ➼ linky by dry-running it against example.com (Only run on a fresh Install)"
  echo "-up,    --update         Update linky"
  echo "-ctmp,  --clean-tmp      Cleans /tmp/ files after run"
  echo "-curls, --clean-urls     Removes noisey junk urls (godeclutter | urless)"
  echo ""
  echo "Example Usage: "
  echo 'linky --url https://example.com --output_dir /path/to/outputdir --github_token ghp_xyz --headers "Authorization: Bearer token; Cookie: cookie_value"'
  echo ""
  echo "Tips: "
  echo "➼ Include API keys in $HOME/Tools/waymore/config.yml to find more links"
  echo "➼ Include multiple github_tokens in $HOME/.config/.github_tokens to avoid rate limits"
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
    mkdir -p "$outputDir/tmp/"
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
    -d|--deep) 
     deep=1
     shift
    ;;
    -ctmp|--clean-tmp) 
     clean_tmp=1
     shift
    ;;  
    -curls|--clean-urls) 
     clean_urls=1
     shift
    ;;      
    *) 
    echo "Error: Invalid option '$key' , try --help for Usage$(rm -rf $outputDir 2>/dev/null)"
    exit 1
    ;;
  esac
done
# Set default values
export url=$url
export outputDir=$outputDir
github_tokens="$HOME/.config/.github_tokens"
if [ -s "$github_tokens" ]; then
  random_token=$(shuf -n 1 "$github_tokens")
  export githubToken=$random_token
else
  export githubToken=$githubToken
fi
export optionalHeaders=$optionalHeaders
export deep=$deep
export clean_tmp=$clean_tmp
#Recheck Values
echo "url: $url"
echo "outputDir: $outputDir"
echo "githubToken: $githubToken"
echo "optionalHeaders: $optionalHeaders"
echo "deep: $deep"
echo "Clean_tmp: $clean_tmp"
echo "Clean_URLs: $clean_urls"
#Setup Vars
originalDir=$(pwd)
# Check if parallel and chromium-chromedriver are installed, and install them if not
if ! command -v chromium >/dev/null 2>&1; then
    echo "➼ chromium-chromedriver is not installed. Installing..."
    sudo apt-get update && sudo apt-get install chromium chromium-chromedriver chromium-common chromium-driver -y
fi
if ! command -v dos2unix >/dev/null 2>&1; then
    echo "➼ dos2unix is not installed. Installing..."
    sudo apt-get update && sudo apt-get install dos2unix -y
fi
if ! command -v go &> /dev/null 2>&1; then
    echo "➼ golang is not installed. Installing..."
    cd /tmp && git clone https://github.com/udhos/update-golang  && cd /tmp/update-golang && sudo ./update-golang.sh
    source /etc/profile.d/golang_path.sh
fi
if ! command -v npm &> /dev/null 2>&1; then
    echo "➼ npm is not installed. Installing..."
    sudo apt-get update && sudo apt-get install npm -y
fi
if ! command -v parallel >/dev/null 2>&1; then
    echo "➼ parallel is not installed. Installing..."
    sudo apt-get update && sudo apt-get install parallel -y
fi
if ! command -v pip3 &> /dev/null; then
   echo "➼ python3-pip is not installed. Installing..." 
   sudo apt-get update && sudo apt-get install python3-pip -y
fi
if ! command -v pipx &> /dev/null; then
   echo "➼ pipx is not installed. Installing..." 
   python3 -m pip install pipx
   python3 -m pipx ensurepath
fi
#Health Check for binaries
binaries=("anew" "arjun" "fget" "gau" "godeclutter" "gospider" "hakrawler" "js-beautify" "katana" "roboxtractor" "scopegen" "scopeview" "subjs" "unfurl" "waybackurls")
for binary in "${binaries[@]}"; do
    if ! command -v "$binary" &> /dev/null; then
        echo "➼ Error: $binary not found"
        echo "➼ Attempting to Install missing tools"
        go install -v github.com/tomnomnom/anew@latest
        pipx install -f "git+https://github.com/s0md3v/Arjun.git" --include-deps
        go install -v github.com/lc/gau/v2/cmd/gau@latest
        GO111MODULE=on && go get -u -v github.com/bp0lr/fget
        go install -v github.com/c3l3si4n/godeclutter@main
        go install -v github.com/jaeles-project/gospider@latest
        go install -v github.com/hakluke/hakrawler@latest
        sudo npm -g install js-beautify
        go install -v github.com/projectdiscovery/katana/cmd/katana@latest
        go env -w GO111MODULE="auto" ; go get -u github.com/Josue87/roboxtractor
        go install -v github.com/Azathothas/BugGPT-Tools/scopegen@main
        sudo wget https://raw.githubusercontent.com/Azathothas/BugGPT-Tools/main/scopeview/scopeview.sh -O /usr/local/bin/scopeview && sudo chmod +xwr /usr/local/bin/scopeview
        go install -v github.com/lc/subjs@latest
        go install -v github.com/tomnomnom/unfurl@latest
        go install -v github.com/tomnomnom/waybackurls@latest
    fi
done
#Health Check for Tools
paths=("$HOME/Tools/JSA/automation.sh" "$HOME/Tools/Arjun/arjun/db/large.txt" "$HOME/Tools/github-search/github-endpoints.py" "$HOME/Tools/" "$HOME/Tools/waymore/waymore.py" "$HOME/Tools/xnLinkFinder/xnLinkFinder.py")
for path in "${paths[@]}"; do
    if [ ! -f "$path" ]; then
        echo "➼ Error: $path not found"
        echo "➼ Attempting to Install missing tools under $HOME/Tools $(mkdir -p $HOME/Tools)"    
        #Arjun
        cd $HOME/Tools && git clone https://github.com/s0md3v/Arjun.git   
        #gwen001/github-search
        cd $HOME/Tools && git clone https://github.com/gwen001/github-search.git && cd $HOME/Tools/github-search && pip3 install -r requirements.txt
        #w9w/JSA
        cd $HOME/Tools && git clone https://github.com/w9w/JSA.git && cd $HOME/Tools/JSA && pip3 install -r requirements.txt
        wget https://raw.githubusercontent.com/Azathothas/BugGPT-Tools/main/linky/assets/JSA_automation.sh -O $HOME/Tools/JSA/automation.sh
        chmod +x $HOME/Tools/JSA/automation.sh && chmod +x $HOME/Tools/JSA/automation/404_js_wayback.sh
        #xnl-h4ck3r/Urless
        cd $HOME/Tools && git clone https://github.com/xnl-h4ck3r/urless.git && cd $HOME/Tools/urless 
        python3 $HOME/Tools/urless/setup.py install
        #xnl-h4ck3r/Waymore
        cd $HOME/Tools && git clone https://github.com/xnl-h4ck3r/waymore.git && cd $HOME/Tools/waymore  && pip3 install -r requirements.txt 
        cd $HOME/Tools/waymore && python3 $HOME/Tools/waymore/setup.py install
        #xnl-h4ck3r/xnLinkFinder 
        cd $HOME/Tools && git clone https://github.com/xnl-h4ck3r/xnLinkFinder.git && cd $HOME/Tools/xnLinkFinder
        python3 $HOME/Tools/xnLinkFinder/setup.py install        
    fi
done
#Extract root domain name 
scope_domain=$(echo "$url" | unfurl apexes)
#Extract full domain name
domain=$(echo "$url" | unfurl domains)
#Set .scope 
echo "Scope is set as: "
echo $scope_domain | scopegen -in | tee $outputDir/.scope
echo ""
#Start Tools
#Gau
echo "➼ Running gau on: $url" && sleep 3s
echo $url | gau --threads 20 | anew $outputDir/tmp/gau-urls.txt
cat $outputDir/tmp/gau-urls.txt | anew -q $outputDir/tmp/urls.txt && clear

#Github-Endpoints
echo "➼ Running github-endpoints on: $url" && sleep 3s
python3 $HOME/Tools/github-search/github-endpoints.py -t $githubToken -d $domain | anew $outputDir/tmp/git-urls.txt
cat $outputDir/tmp/git-urls.txt | anew $outputDir/tmp/urls.txt

#GoSpider
echo "➼ Running GoSpider on: $url "
if [ -n "$optionalHeaders" ]; then 
  if [ -n "$deep" ]; then
    gospider -s $url --other-source --include-subs --include-other-source --concurrent 50 --depth 5 -H "$optionalHeaders" --quiet | grep -aEo 'https?://[^ ]+' | sed 's/]$//' | anew $outputDir/tmp/gospider-urls.txt
  else
    gospider -s $url --other-source --include-subs --include-other-source --concurrent 20 -H "$optionalHeaders" --quiet | grep -aEo 'https?://[^ ]+' | sed 's/]$//' |  anew $outputDir/tmp/gospider-urls.txt
  fi
else
  if [ -n "$deep" ]; then
    gospider -s $url --other-source --include-subs --include-other-source --concurrent 50 --depth 5 --quiet | grep -aEo 'https?://[^ ]+' | sed 's/]$//' | anew $outputDir/tmp/gospider-urls.txt
  else 
    gospider -s $url --other-source --include-subs --include-other-source --concurrent 20 --quiet | grep -aEo 'https?://[^ ]+' | sed 's/]$//' | anew $outputDir/tmp/gospider-urls.txt
  fi
fi
cat $outputDir/tmp/gospider-urls.txt | anew -q $outputDir/tmp/urls.txt && clear 

#Hakrawler
echo "➼ Running hakrawler on: $url" && sleep 3s
if [ -n "$optionalHeaders" ]; then 
   if [ -n "$deep" ]; then
   echo $url | hakrawler -d 5 -insecure -t 50 -h "$optionalHeaders" | anew $outputDir/tmp/hak-urls.txt
  else
   echo $url | hakrawler -insecure -t 20 -h "$optionalHeaders" | anew $outputDir/tmp/hak-urls.txt
  fi
else
   if [ -n "$deep" ]; then
    echo $url | hakrawler -d 5 -insecure -t 50 | anew $outputDir/tmp/hak-urls.txt
  else 
   echo $url | hakrawler -insecure -t 20 | anew $outputDir/tmp/hak-urls.txt
  fi
fi 
cat $outputDir/tmp/hak-urls.txt | anew -q $outputDir/tmp/urls.txt && clear

#Katana
echo "➼ Running Katana on: $url" && sleep 3s
if [ -n "$optionalHeaders" ]; then 
   if [ -n "$deep" ]; then
    echo $url | katana -d 5 -H "$optionalHeaders" -o $outputDir/tmp/katana-urls.txt 
  else 
    echo $url | katana -H "$optionalHeaders" -o $outputDir/tmp/katana-urls.txt 
  fi
else
   if [ -n "$deep" ]; then
    echo $url | katana -d 5 -o $outputDir/tmp/katana-urls.txt 
  else
    echo $url | katana -o $outputDir/tmp/katana-urls.txt 
  fi
fi
cat $outputDir/tmp/katana-urls.txt | anew -q $outputDir/tmp/urls.txt && clear 

#Robots.txt
echo "➼ Finding all robots.txt Endpoints on: $url" 
roboxtractor -u $url -s -m 1 -wb -v | sort -u | awk '{print "/" $1}' | anew $outputDir/robots.txt

#XnLinkFinder
echo "➼ Running xnLinkFinder on: $url" && sleep 3s
if [ -n "$optionalHeaders" ]; then 
   if [ -n "$deep" ]; then
    python3 $HOME/Tools/xnLinkFinder/xnLinkFinder.py -i $url -H "$optionalHeaders" -sp $url -d 5 -sf .*$scope_domain -v -insecure -o $outputDir/tmp/xnl-urls.txt -op $outputDir/tmp/xnl-parameters.txt
  else
    python3 $HOME/Tools/xnLinkFinder/xnLinkFinder.py -i $url -H "$optionalHeaders" -sp $url -sf .*$scope_domain -v -insecure -o $outputDir/tmp/xnl-urls.txt -op $outputDir/tmp/xnl-parameters.txt
  fi
else
  if [ -n "$deep" ]; then
    python3 $HOME/Tools/xnLinkFinder/xnLinkFinder.py -i $url -sp $url -d 5 -sf .*$scope_domain -v -insecure -o $outputDir/tmp/xnl-urls.txt -op $outputDir/tmp/xnl-parameters.txt
  else
    python3 $HOME/Tools/xnLinkFinder/xnLinkFinder.py -i $url -sp $url -sf .*$scope_domain -v -insecure -o $outputDir/tmp/xnl-urls.txt -op $outputDir/tmp/xnl-parameters.txt
  fi
fi
cat $outputDir/tmp/xnl-urls.txt | anew $outputDir/tmp/urls.txt
cat $outputDir/tmp/xnl-parameters.txt | anew $outputDir/parameters.txt
clear 

#Waymore
echo "➼ Running Waymore on: $url"
mkdir -p $outputDir/waymore/waymore-responses
cd $HOME/Tools/waymore && python3 $HOME/Tools/waymore/waymore.py --input $domain -xcc --output-urls $outputDir/waymore/waymore-urls.txt --output-responses $outputDir/waymore/waymore-responses --verbose --processes 5
cat $outputDir/waymore/waymore-urls.txt | anew $outputDir/tmp/urls.txt
#XnLinkfinder for Waymore
cd $HOME/Tools/xnLinkFinder && python3 $HOME/Tools/xnLinkFinder/xnLinkFinder.py -i $outputDir/waymore/waymore-responses --origin --output $outputDir/waymore/waymore-linkfinder.txt --output-params $outputDir/waymore/waymore-params.txt
cat $outputDir/waymore/waymore-linkfinder.txt | grep -aEo 'https?://[^ ]+' | sed 's/]$//' | anew $outputDir/tmp/urls.txt
cat $outputDir/waymore/waymore-params.txt | anew $outputDir/parameters.txt
cat $outputDir/waymore/waymore-linkfinder.txt | cut -d'[' -f1 | anew $outputDir/endpoints.txt

#Dedupe & Filter Scope
sort -u $outputDir/tmp/urls.txt -o $outputDir/tmp/urls.txt
if [ -n "$clean_urls" ]; then 
  echo "➼ Removing Junk URLs (urless): $url"
  cd $HOME/Tools/urless && python3 $HOME/Tools/urless/urless.py --input $outputDir/tmp/urls.txt --no-banner --language --filter-extensions --keep-human-written	--keep-yyyymm -o $outputDir/tmp/urless.txt
  echo "➼ Decluttering URLs (godeclutter): $url" 
  cat $outputDir/tmp/urls.txt | godeclutter | anew $outputDir/tmp/decluttered-urls.txt
  #merge and filter scope
  cat $outputDir/tmp/urless.txt $outputDir/tmp/decluttered-urls.txt | scopeview -s $outputDir/.scope | sort -u -o $outputDir/urls.txt
else
  cat $outputDir/tmp/urls.txt | scopeview -s $outputDir/.scope | sort -u -o $outputDir/urls.txt
fi

#JavaScript enum
cat $outputDir/urls.txt | grep -aEi "\.js([?#].*)?$" | anew $outputDir/js.txt
echo "➼ Downloading all JS files [fGET] $(mkdir -p $outputDir/jsfiles)"
cat $outputDir/js.txt | fget -o $outputDir/jsfiles --random-agent --verbose --workers 50
mv $outputDir/jsfiles/results/**/**/** $outputDir/jsfiles
#Beautify
echo "➼ Beautifying all JS files [js-beautifier]"
js-beautify -r $outputDir/jsfiles/**/**/**/**/**/**.js
#XnLinkfinder for JS
echo "➼ Finding additional links & Paramas from JSfiles"
rm -rf /tmp/$domain-jsfiles 2>/dev/null
cp -r $outputDir/jsfiles /tmp/$domain-jsfiles
echo "➼ Finding Links & Params [xnLinkFinder]"
cd $HOME/Tools/xnLinkFinder && python3 $HOME/Tools/xnLinkFinder/xnLinkFinder.py -i /tmp/$domain-jsfiles --origin --output /tmp/$domain-jsfile-links.txt --output-params /tmp/$domain-jsfiles-params.txt
cp /tmp/$domain-jsfile-links.txt $outputDir/jsfile-links.txt && cp /tmp/$domain-jsfiles-params.txt $outputDir/jsfiles-params.txt
cat $outputDir/jsfile-links.txt | cut -d'[' -f1 | anew $outputDir/endpoints.txt
cat $outputDir/jsfile-links.txt | grep -aEo 'https?://[^ ]+' | sed 's/]$//' | anew $outputDir/tmp/urls.txt
cat $outputDir/jsfiles-params.txt | anew $outputDir/parameters.txt 
echo "=========================================="

#Endpoints
cat $outputDir/urls.txt | sed '$!N; /^\(.*\)\n\1$/!P; D'| grep -P '\.php|\.asp|\.js|\.jsp|\.jsp' | anew $outputDir/endpoints.txt
sed -i 's#^/##' $outputDir/endpoints.txt
#Parameters
cat $outputDir/urls.txt | grep -Po '(?:\?|\&)(?<key>[\w]+)(?:\=|\&?)(?<value>[\w+,.-]*)' | tr -d '?' | tr -d '&' | sed 's/=.*//' | sort -u | uniq | anew $outputDir/parameters.txt

#QOL Changes
find $outputDir -type f -size 0 -delete
find $outputDir -type f -not -name ".*" -exec sort -u {} -o {} \;  
cd $originalDir
echo "➼ All Links Scraped and Saved in: $outputDir"
files=("$outputDir/endpoints.txt" "$outputDir/js.txt" "$outputDir/jsfile-links.txt" "$outputDir/jsfiles-params.txt" "$outputDir/parameters.txt" "$outputDir/robots.txt" "$outputDir/urls.txt" )
labels=("Endpoints" "JavaScript URLs" "JavaScript Links & Endpoints" "JavaScript Parameters" "Parameters" "Robots.TXT" "URLs")
for i in "${!files[@]}"; do
    if [ -f "${files[i]}" ]; then
        count=$(wc -l < "${files[i]}")
        echo "➼ Total ${labels[i]} (${files[i]}) --> ${count// /}"
    else
        echo "➼ File ${files[i]} not found"
    fi
done
#Removes Temp
if [ -n "$clean_tmp" ]; then
rm -rf $outputDir/tmp 2>/dev/null
fi

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