# 🧠 Codebase Genius
**AI-Powered Codebase Repo Analyzer Documentation Generator**

Automatically analyze GitHub repositories and generate comprehensive documentation using multi-agent AI architecture.


## ✨ Features

- 🔄 **Automatic Repository Cloning** - Fetch any public GitHub repository
- 📂 **Structure Mapping** - Generate complete file tree visualization
- 🔍 **Code Analysis** - Analyze Python code structure, classes, and functions
- 📊 **Visual Diagrams** - Auto-generate Mermaid code context graphs
- 📝 **Markdown Documentation** - Professional, structured documentation
- 🤖 **AI-Powered Insights** - LLM-based code understanding and summarization
- 🌐 **Web Interface** - Beautiful Streamlit UI for easy interaction

## 🏗️ Architecture

Codebase Genius uses a **multi-agent architecture** built with JacLang:

```
┌─────────────────────────────────────────────┐
│          Streamlit Frontend (app.jac)       │
└─────────────────┬───────────────────────────┘
                  │ Execute
                  ▼
┌─────────────────────────────────────────────┐
│         JacLang Pipeline (main.jac)         │
│  ┌─────────────────────────────────────┐    │
│  │  Agent 1: RepoMapper                │    │
│  │  - Clone repository                 │    │
│  │  - Map file structure               │    │
│  │  - Read README                      │    │
│  └─────────────────────────────────────┘    │
│                    │                        │
│                    ▼                        │
│  ┌─────────────────────────────────────┐    │
│  │  Agent 2: CodeAnalyzer              │    │
│  │  - Parse Python files               │    │
│  │  - Extract classes/functions        │    │
│  │  - Generate CCG diagram             │    │
│  └─────────────────────────────────────┘    │
│                    │                        │
│                    ▼                        │
│  ┌─────────────────────────────────────┐    │
│  │  Agent 3: DocGenie                  │    │
│  │  - Generate markdown docs           │    │
│  │  - Format and structure             │    │
│  │  - Add visual elements              │    │
│  └─────────────────────────────────────┘    │
└─────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Python 3.8 or higher
- Git
- huggingface/meta-llama/Llama-3.3-70B-Instruct (or any compatible LLM)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/devMaLoba/GenAI_Codebase-Genius.git
cd Codebase-Genius
```

2. **Create virtual environment**
```bash
python -m venv venv
source venv/bin/activate
venv\Scripts\activate (On Windows) 
```

3. **Install dependencies**
```bash
pip install -r requirements.txt
```

4. **Install JacLang and its Components(byllm, jac-cloud, etc)**
```bash
pip install jaseci
```

5. **Set up LLM**
```bash
# Set- Up Llama from Hugging face
huggingface/meta-llama/Llama-3.3-70B-Instruct
```

6. **Configure environment variables**
```bash
cp .env.example .env
# Edit .env with your settings
# Export your environment variables
     export Llama_API_KEY = "hf_"
```

### Running the Application
**Terminal 1: Start JAC Server Backend**
```bash
cd Codebase-Genius
source venv/bin/activate
jac serve main.jac
```

**Terminal 2: Start Streamlit Frontend**
```bash
cd Codebase-Genius
source venv/bin/activate
jac streamlit app.jac 
```
## 📖 Usage

### Via Web Interface

1. Open http://localhost:8501 in your browser
2. You will be prompted to enter user authentication for the backend
3. Use Postman to create a new JAC Server account if you haven't
4. Key in your Email and Password to Log In
5. Enter a GitHub repository URL (e.g., `https://github.com/jaseci-labs/Agentic-AI/tree/main/task_manager/byllm`) 
6. Click "🔎 Analyze Repository"
7. Wait for AI processing (typically 2-3 Minutes)
8. View the generated documentation

## 📁 Project Structure

```
Codebase-Genius/
├── main.jac              # Main JacLang pipeline
├── app.py                # Streamlit frontend
├── .env                  # Environment configuration
├── .env.example          # Example environment file
└──  README.md            # Readme file 
```

## 🧪 Testing

### Test Individual Components

**Test Main:**
```bash
jac run main.jac
```

**Test App:**
```bash
jac run app.jac
```

## 🐛 Troubleshooting

### Common Issues

**1. "LLM connection refused"**
- Check your API Keys, test with Postman

**2. "Git clone failed"**
- Ensure Git is installed: `git --version`
- Check repository URL is correct
- Verify internet connection

## 🎯 Roadmap

- [x] Basic repository cloning and analysis
- [x] Programming language code parsing
- [x] Mermaid diagram generation
- [x] Streamlit web interface
- [x] Support for more languages (JavaScript, Java, Go)
- [ ] Advanced code analysis (call graphs, dependency trees)
- [ ] GitHub API integration for private repos
- [ ] Multiple LLM provider support
- [ ] Documentation templates customization
- [ ] Batch processing for multiple repos
- [ ] CI/CD integration

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [JacLang & Jaseci](https://www.jac-lang.org/) - Multi-agent programming language
- [Streamlit](https://streamlit.io/) - App framework for ML/AI
- [Llama-3.3-70B-Instruct](https://huggingface.co/meta-llama/) - LLM runtime

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/devMaLoba/GenAI_Codebase-Genius/issues)
- **Discussions**: [GitHub Discussions](https://github.com/devMaLoba/GenAI_Codebase-Genius/discussions)
- **Email**: ephraimtheextreme@gmail.com

## ⭐ Show Your Support

If you find this project helpful, please consider giving it a star on GitHub!

---

**Built with ❤️ using JacLang and Streamlit**