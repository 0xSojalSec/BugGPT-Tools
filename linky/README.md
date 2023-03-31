Revamped Version of [**mux0x/cold.sh**](https://github.com/mux0x/cold.sh) ; A Fancy Wrapper around [**gau**](https://github.com/lc/gau), [**github-endpoints**](https://github.com/gwen001/github-search/blob/master/github-endpoints.py), [**gospider**](https://github.com/jaeles-project/gospider), [**hakrawler**](https://github.com/hakluke/hakrawler), [**JSA**](https://github.com/w9w/JSA), [**katana**](https://github.com/projectdiscovery/katana), [**subJS**](https://github.com/lc/subjs), [**waybackurls**](https://github.com/tomnomnom/waybackurls) & [**xnLinkFinder**](https://github.com/xnl-h4ck3r/xnLinkFinder) to find as much Links, Endpoints & Params as possible.

### **Installation**:
 - **Bash**: 
```bash
sudo wget https://raw.githubusercontent.com/Azathothas/BugGPT-Tools/main/linky/linky.sh -O /usr/local/bin/linky && sudo chmod +xwr /usr/local/bin/linky
``` 


### Usage: 
```bash
#Will auto install dependency and Initialize upon first run. manually supply -gh if ~/.config/.github_tokens doesn't exist
linky -u https://example.com -o /tmp/example.com -gh $(head -n 1 ~/.config/.github_tokens)
```
`linky --help`
```bash
──╔╗──╔╗
╔╗╠╬═╦╣╠╦╦╗
║╚╣║║║║═╣║║
╚═╩╩╩═╩╩╬╗║
────────╚═╝
Usage: linky -u <url> -o /path/to/outputdir -gh <github_token> -h <optional Headers>

Extended Help
-u,  --url            Specify the URL to scrape (Required)
-o,  --output_dir     Specify the directory to save the output files (Required)
-gh, --github_token   Specify a GitHub personal access token (Required if you want to fetch from github)
-h,  --headers        Specify additional headers or cookies to use in the HTTP request (optional)
-up, --update         Update linky

Example Usage:
linky --url https://example.com --output_dir /path/to/outputdir --github_token ghp_xyz --headers "Authorization: Bearer token; Cookie: cookie_value"
```
