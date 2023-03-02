use std::env;
use std::fs::File;
use std::io::{BufRead, BufReader};
use std::process;

fn main() {
    let args: Vec<String> = env::args().collect();

    let in_scope = args.iter().any(|arg| arg == "-in");
    let out_scope = args.iter().any(|arg| arg == "-os");

    if !in_scope && !out_scope {
        eprintln!("Please specify either -in or -os");
        process::exit(1);
    }

    let input: Box<dyn BufRead> = match args.get(2) {
        Some(path) => Box::new(BufReader::new(File::open(path).unwrap())),
        None => Box::new(BufReader::new(std::io::stdin())),
    };

    let output: Vec<String> = input
        .lines()
        .filter_map(Result::ok)
        .map(|line| {
            let domain = line.trim();
            if in_scope {
                format!(".*\\.{}$", domain.replace(".", "\\.")) 
            } else {
                format!("!.*{}$", domain.replace(".", "\\.")) 
            }
        })
        .collect();

    println!("{}", output.join("\n"));
}
