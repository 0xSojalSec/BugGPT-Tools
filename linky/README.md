


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
