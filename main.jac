import from byllm.llm { Model }
import os;
import json;
import subprocess;
import from dotenv { load_dotenv }

glob llm = Model(model_name = "huggingface/meta-llama/Llama-3.3-70B-Instruct", verbose= True);

def generate_response(utterance: str) -> str by llm();

def extract_repo_info(url: str) -> dict {
    """Extract owner and repo name from GitHub URL""";
    # Clean and normalize the URL
    url = url.strip();
    
    # Handle tree/blob URLs by extracting just the repo part
    if '/tree/' in url or '/blob/' in url {
        url = url.split('/tree/')[0].split('/blob/')[0];
    }
    
    # Ensure URL has protocol
    if not url.startswith('http') {
        url = 'https://' + url;
    }
    
    parts = url.rstrip('/').split('/');
    if len(parts) >= 5 {  # https://github.com/owner/repo
        return {
            "owner": parts[-2],
            "repo": parts[-1],
            "full_url": url
        };
    }
    return {};
}

def clone_and_analyze_repo(url: str) -> dict {
    """Clone repo and analyze its structure""";
    try {
        # Clean and extract repo info
        repo_info = extract_repo_info(url);
        
        if not repo_info {
            return {"error": "Invalid GitHub URL format", "cloned": False};
        }
        
        repo_name = repo_info.get("repo", "unknown");
        clone_url = repo_info.get("full_url", url);
        clone_path = f"/tmp/{repo_name}";
        
        # Remove existing clone
        subprocess.run(["rm", "-rf", clone_path], capture_output=True);
        
        print(f"📥 Cloning repository from {clone_url}...");
        result = subprocess.run(
            ["git", "clone", "--depth", "1", clone_url, clone_path],
            capture_output=True,
            text=True,
            timeout=180
        );
        
        if result.returncode != 0 {
            return {"error": f"Failed to clone: {result.stderr}", "cloned": False};
        }
        
        print(f"✅ Repository cloned to {clone_path}");
        
        # Get file structure
        structure_result = subprocess.run(
            ["find", clone_path, "-type", "f"],
            capture_output=True,
            text=True
        );
        
        files = structure_result.stdout.strip().split('\n');
        structure = {
            "total_files": len(files),
            "files": [f.replace(clone_path + '/', '') for f in files[:50]]  # First 50 files
        };
        
        # Read README if exists
        readme_content = "";
        for readme_name in ["README.md", "README.txt", "README"] {
            readme_path = os.path.join(clone_path, readme_name);
            if os.path.exists(readme_path) {
                with open(readme_path, 'r', encoding='utf-8', errors='ignore') as f {
                    readme_content = f.read()[:2000];  # First 2000 chars
                    break;
                }
            }
        }
        
        # Detect programming languages
        extensions = {};
        for file in files {
            ext = os.path.splitext(file)[1];
            if ext {
                extensions[ext] = extensions.get(ext, 0) + 1;
            }
        }
        
        # Map common extensions to languages
        lang_map = {
            ".py": "Python", ".js": "JavaScript", ".ts": "TypeScript",
            ".java": "Java", ".cpp": "C++", ".c": "C", ".go": "Go",
            ".rs": "Rust", ".rb": "Ruby", ".php": "PHP", ".swift": "Swift",
            ".kt": "Kotlin", ".jac": "Jac", ".md": "Markdown", ".json": "JSON",
            ".yaml": "YAML", ".yml": "YAML", ".html": "HTML", ".css": "CSS"
        };
        
        languages = {};
        total = sum(extensions.values());
        for (ext, count) in extensions.items() {
            if ext in lang_map {
                lang = lang_map[ext];
                percentage = (count / total) * 100 if total > 0 else 0;
                languages[lang] = round(percentage, 2);
            }
        }
        
        return {
            "cloned": True,
            "path": clone_path,
            "structure": structure,
            "readme": readme_content,
            "languages": languages,
            "repo_info": repo_info
        };
        
    } except subprocess.TimeoutExpired {
        return {"error": "Clone timeout", "cloned": False};
    } except Exception as e {
        return {"error": str(e), "cloned": False};
    }
}

walker codebase_genius {
    has utterance: str;
    has doc_results: dict = {};

    can analyze with `root entry {
        # Generate initial response
        response = generate_response(self.utterance);
        print(f"🤖 Codebase Genius responds: {response}");
        print("📥 Initiating Repo analysis...");
        
        # Store LLM response for frontend
        llm_initial_response = response;
        
        # Extract and clean GitHub URL from utterance
        url = self.utterance.strip();
        
        # Remove any leading colons or whitespace
        while url.startswith(':') or url.startswith(' ') {
            url = url[1:];
        }
        
        url = url.strip();
        
        # Validate URL
        if not ('github.com' in url) {
            print("⚠️ No valid GitHub URL found in utterance");
            report {"error": "No valid GitHub URL provided"};
            disengage;
        }
        
        # Ensure URL has protocol
        if not url.startswith('http') {
            url = 'https://' + url;
        }
        
        print(f"🔗 Processing GitHub URL: {url}");
        
        # Clone and analyze repository
        repo_data = clone_and_analyze_repo(url);
        
        if not repo_data.get("cloned") {
            error_msg = repo_data.get("error", "Unknown error");
            print(f"❌ Error: {error_msg}");
            report {"error": error_msg};
            disengage;
        }
        
        print("✅ Repository cloned and analyzed!");
        
        # Step 1: RepoMapper Analysis
        print("🗺️ RepoMapper: Analyzing repository structure...");
        def validate_github_url(url: str) -> str by llm();
        validation = validate_github_url(url);
        print(f"✅ URL Validation: {validation}");
        
        def analyze_repo_structure(structure: dict, repo_info: dict) -> str by llm();
        structure_analysis = analyze_repo_structure(
            repo_data["structure"],
            repo_data["repo_info"]
        );
        print(f"✅ Structure Analysis: {structure_analysis}");
        
        readme_content = repo_data["readme"];
        if readme_content {
            def summarize_readme(readme: str) -> str by llm();
            readme_summary = summarize_readme(readme_content);
            print(f"✅ README Summary: {readme_summary}");
        } else {
            readme_summary = "No README found";
            print("⚠️ No README file found in repository");
        }
        
        # Step 2: CodeAnalyzer Analysis
        print("🛠️ CodeAnalyzer: Analyzing code and languages...");
        languages = repo_data["languages"];
        
        def analyze_programming_languages(languages: dict, repo_info: dict) -> str by llm();
        languages_analysis = analyze_programming_languages(languages, repo_data["repo_info"]);
        print(f"✅ Languages Analysis: {languages_analysis}");
        
        def suggest_code_improvements(languages: dict, structure: dict) -> str by llm();
        improvements = suggest_code_improvements(languages, repo_data["structure"]);
        print(f"✅ Code Improvements: {improvements}");
        
        # Step 3: DocGenie - Generate Documentation
        print("📚 DocGenie: Generating comprehensive documentation...");
        
        def generate_mermaid_architecture(structure: dict, languages: dict) -> str by llm();
        mermaid_arch = generate_mermaid_architecture(repo_data["structure"], languages);
        print(f"✅ Mermaid Architecture: {mermaid_arch}");
        
        def generate_comprehensive_documentation(
            url: str,
            validation: str,
            structure_analysis: str,
            readme_summary: str,
            languages_analysis: str,
            improvements: str,
            languages: dict,
            structure: dict
        ) -> str by llm();
        
        comprehensive_docs = generate_comprehensive_documentation(
            url,
            validation,
            structure_analysis,
            readme_summary,
            languages_analysis,
            improvements,
            languages,
            repo_data["structure"]
        );
        print(f"✅ Comprehensive Documentation Generated!");
        
        # Prepare final report
        final_report = {
            "url": url,
            "repo_info": repo_data["repo_info"],
            "repomapper": {
                "validation": validation,
                "structure_analysis": structure_analysis,
                "readme_summary": readme_summary,
                "readme_full": readme_content[:500]  # First 500 chars
            },
            "codeanalyzer": {
                "languages": languages,
                "languages_analysis": languages_analysis,
                "improvements": improvements
            },
            "docgenie": {
                "documentation": comprehensive_docs,
                "mermaid": {
                    "architecture": mermaid_arch
                },
                "structure": repo_data["structure"]
            }
        };
        
        self.doc_results = final_report;
        
        print("🚀 Documentation generation process complete!");
        print("📝 Complete analysis report ready!");
        
        # Report the final results
        report final_report;
    }
}

with entry {
    # Create sample nodes for the graph structure (optional, for visualization)
    # The walker now does all the work inline
    print("🤖 Codebase Genius initialized!");
    print("📡 Waiting for API requests...");
}