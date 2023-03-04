Slightly revamped vesion of TomNomNom's [Inscope](https://github.com/tomnomnom/hacks/tree/master/inscope) that allows custom **`.scope`** to be defined using **`-s`** or **`--scope`** options

## Installation
- **Bash** : `➼ `
- **Go** : `➼ go install -v github.com/Azathothas/BugGPT-Tools/scopeview@main`
- **Rust** : `➼`
## Usage
Same as you would use tomnomnom's [Inscope](https://github.com/tomnomnom/hacks/tree/master/inscope).
Difference being, able to pass/specify **`.scope`**

**Examples**: Generate a  **`.scope`** file using [scopegen](https://github.com/Azathothas/BugGPT-Tools/tree/main/scopegen)
```bash
➼ cat inscope-domains.txt
       example.com
       example.org
       abc.example.com
➼ cat outscope-domains.txt
       oos.example.com
       oos.abc.example.org
 ```
 Then,
 ```bash 
 ➼ scopegen -t inscope-domains.txt -in && scopegen -t outscope-domains.txt -os | tee -a .scope
 ``` 
 ```bash 
➼ cat .scope
       .*\.example\.com$
       .*\.example\.org$
       .*\.abc\.example\.com$
       !.*oos\.example\.com$
       !.*oos\.abc\.example\.org$
 ```
`cat | pipe` your stream/text & pass your **`.scope`** to **scopeview**
```bash
➼ cat your-data-to-be-filtered.ext | scopeview -s .scope-file 
➼ some-output-stream | scopeview -s .scope-file
```
Or you can just simply place a **`.scope`** file in your working directory or cwd's parent.

