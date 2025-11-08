import streamlit as st;
import requests;
import json;
import from datetime { datetime }
import os;
import from dotenv { load_dotenv }

with entry {
    load_dotenv();
    st.set_page_config(
        page_title='Codebase Genius',
        page_icon='🤖',
        layout='wide',
        initial_sidebar_state='expanded'
    );
    let JAC_API_URL = 'http://localhost:8000';
    let JAC_LOGIN_URL = f'{JAC_API_URL}/user/login';
    let JAC_WALKER_URL = f'{JAC_API_URL}/walker/codebase_genius';
    
    st.markdown(
        "\n<style>\n    body {\n        background-color: #0e1117;\n        color: #fafafa;\n    }\n    .stTextInput>div>div>input {\n        background-color: #262730;\n        color: #fff;\n    }\n    .st-emotion-cache-1jicfl2 {\n        background-color: #262730;\n        color: #fff;\n    }\n    .terminal {\n        background-color: #000;\n        color: #00FF88;\n        font-family: 'Courier New', monospace;\n        padding: 10px;\n        border-radius: 8px;\n        max-height: 350px;\n        overflow-y: auto;\n    }\n    .success-box {\n        background-color: #1a4d2e;\n        padding: 15px;\n        border-radius: 8px;\n        margin: 10px 0;\n    }\n    .info-box {\n        background-color: #1a3a4d;\n        padding: 15px;\n        border-radius: 8px;\n        margin: 10px 0;\n    }\n</style>\n",
        unsafe_allow_html=True
    );
    st.sidebar.title('📂 Repo History');
    let HISTORY_FILE = 'repo_history.json';
}

def load_history() {
    try {
        with open(HISTORY_FILE, 'r') as f {
            return json.load(f);
        }
    } except Exception as e {
        return [];
    }
}

def save_to_history(url: Any) {
    let history = load_history();
    if (url not in [h['url'] for h in history]) {
        history.append({'url': url, 'timestamp': str(datetime.now())});
        with open(HISTORY_FILE, 'w') as f {
            json.dump(history, f);
        }
    }
}

def login_to_jac(email: str, password: str) {
    try {
        let response = requests.post(
            JAC_LOGIN_URL,
            json={'email': email, 'password': password},
            timeout=30
        );
        if (response.status_code == 200) {
            let data = response.json();
            return (data.get('token'), None);
        } else {
            return (None, f"Login failed: {response.status_code}");
        }
    } except Exception as e {
        return (None, f"Login error: {str(e)}");
    }
}

with entry {
    # Initialize session state
    if ('jac_token' not in st.session_state) {
        st.session_state.jac_token = None;
    }
    if ('user_email' not in st.session_state) {
        st.session_state.user_email = None;
    }
    if ('last_analysis' not in st.session_state) {
        st.session_state.last_analysis = None;
    }
    
    # Sidebar Authentication
    st.sidebar.markdown('### 🔐 Authentication');
    
    if (st.session_state.jac_token is None) {
        let email = st.sidebar.text_input(
            'Email:', 
            value=os.getenv('JAC_EMAIL', ''),
            key='email_input'
        );
        let password = st.sidebar.text_input(
            'Password:', 
            value=os.getenv('JAC_PASSWORD', ''),
            type='password',
            key='password_input'
        );
        
        if st.sidebar.button('🔓 Login') {
            if (email and password) {
                with st.sidebar {
                    with st.spinner('Logging in...') {
                        let (token, error) = login_to_jac(email, password);
                        if token {
                            st.session_state.jac_token = token;
                            st.session_state.user_email = email;
                            st.success('✅ Login successful!');
                            st.rerun();
                        } else {
                            st.error(f'❌ {error}');
                        }
                    }
                }
            } else {
                st.sidebar.warning('Please enter email and password');
            }
        }
    } else {
        st.sidebar.markdown(
            f"<div class='success-box'>✅ Logged in as: {st.session_state.user_email}</div>",
            unsafe_allow_html=True
        );
        if st.sidebar.button('🔒 Logout') {
            st.session_state.jac_token = None;
            st.session_state.user_email = None;
            st.session_state.last_analysis = None;
            st.rerun();
        }
    }
    
    st.sidebar.markdown('---');
    
    # Repository History
    let history = load_history();
    let selected_history = st.sidebar.selectbox(
        'Select a previous repo:', ([''] + [h['url'] for h in history])
    );
    
    # Main Content
    st.title('🚀 Codebase Genius — AI-Powered Repo Analyzer');
    st.caption('Analyze GitHub repositories with Jac + LLM backend via RepoMapper → CodeAnalyzer → DocGenie pipeline.');
    
    # Add helpful tips
    with st.expander('💡 Tips for Best Results') {
        st.markdown("""
        - **For large repositories**: Analysis may take 2-3 minutes
        - **URL formats supported**: 
          - `https://github.com/owner/repo`
          - `github.com/owner/repo`
          - URLs with `/tree/main/...` (we'll extract the base repo)
        - **First time?** Try a smaller repo like: `https://github.com/octocat/Hello-World`
        """);
    }
    
    # Check if logged in
    if (st.session_state.jac_token is None) {
        st.warning('⚠️ Please login in the sidebar to use the analyzer.');
        st.stop();
    }
    
    let github_url = st.text_input(
        'Enter a GitHub repository URL:', 
        value=selected_history if selected_history else '',
        placeholder='https://github.com/username/repository'
    );
    
    let analyze_btn = st.button('🔍 Analyze Repository');
    
    if (analyze_btn and github_url) {
        # Create progress containers
        progress_container = st.container();
        
        with progress_container {
            st.markdown('### 📊 Analysis Progress');
            
            # Progress indicators
            llm_status = st.empty();
            repo_status = st.empty();
            url_status = st.empty();
            clone_status = st.empty();
            mapper_status = st.empty();
            analyzer_status = st.empty();
            docgenie_status = st.empty();
            
            # Terminal-style output container
            st.markdown('<div class="terminal">', unsafe_allow_html=True);
            terminal_output = st.empty();
            st.markdown('</div>', unsafe_allow_html=True);
            
            # Initial status
            llm_status.info('🤖 Sending request to LLM...');
            terminal_lines = ['🔄 Initiating analysis...'];
            terminal_output.code('\n'.join(terminal_lines), language='');
        }
        
        try {
            let payload = {
                'utterance': github_url
            };
            
            let headers = {
                'Content-Type': 'application/json',
                'Authorization': f'Bearer {st.session_state.jac_token}'
            };
            
            # Update status
            terminal_lines.append('📡 Connecting to backend...');
            terminal_output.code('\n'.join(terminal_lines), language='');
            
            let response = requests.post(
                JAC_WALKER_URL, 
                json=payload, 
                headers=headers,
                timeout=240
            );
            
            # Update with simulated progress (since we can't stream in real-time)
            llm_status.success('✅ LLM Response Received');
            terminal_lines.append('✅ Backend connection established');
            terminal_lines.append('📥 Initiating Repo analysis...');
            terminal_output.code('\n'.join(terminal_lines), language='');
            
            repo_status.info('🔗 Processing GitHub URL...');
            terminal_lines.append(f'🔗 Processing GitHub URL: {github_url}');
            terminal_output.code('\n'.join(terminal_lines), language='');
            
            clone_status.info('📥 Cloning repository (this may take 1-3 minutes)...');
            terminal_lines.append('📥 Cloning repository...');
            terminal_output.code('\n'.join(terminal_lines), language='');
            
            if (response.status_code == 200) {
                let data = response.json();
                let reports = data.get('reports', []);
                
                if reports {
                    let report = reports[0];
                    
                    # Show LLM response if available
                    if 'llm_response' in report {
                        llm_status.success('✅ LLM Response Received');
                        with st.expander('🤖 LLM Initial Analysis', expanded=True) {
                            st.markdown(report['llm_response']);
                        }
                    } else {
                        llm_status.success('✅ LLM Response Received');
                    }
                    
                    # Update all statuses to success
                    url_status.success('✅ URL Validated');
                    clone_status.success('✅ Repository Cloned');
                    mapper_status = st.empty();
                    mapper_status.success('✅ RepoMapper Analysis Complete');
                    analyzer_status = st.empty();
                    analyzer_status.success('✅ CodeAnalyzer Processing Complete');
                    docgenie_status.success('✅ DocGenie Documentation Generated');
                    
                    terminal_lines.append('✅ Repository cloned successfully');
                    terminal_lines.append('🗺️ RepoMapper: Analyzing repository structure...');
                    terminal_lines.append('✅ Structure analysis complete');
                    terminal_lines.append('🛠️ CodeAnalyzer: Analyzing code and languages...');
                    terminal_lines.append('✅ Language analysis complete');
                    terminal_lines.append('📚 DocGenie: Generating comprehensive documentation...');
                    terminal_lines.append('✅ Documentation generation complete!');
                    terminal_lines.append('🚀 Analysis pipeline finished successfully!');
                    terminal_output.code('\n'.join(terminal_lines), language='');
                    
                    st.session_state.last_analysis = report;
                    save_to_history(github_url);
                    st.success('✅ Analysis complete! All nodes processed successfully.');
                    st.balloons();
                } else {
                    terminal_lines.append('⚠️ Analysis completed but no reports generated');
                    terminal_output.code('\n'.join(terminal_lines), language='');
                    st.warning('⚠️ Analysis completed but no reports generated.');
                    st.json(data);
                }
                
            } else {
                terminal_lines.append(f'❌ Backend error: {response.status_code}');
                terminal_output.code('\n'.join(terminal_lines), language='');
                
                if (response.status_code == 401 or response.status_code == 403) {
                    st.error('❌ Authentication failed. Please login again.');
                    st.session_state.jac_token = None;
                    st.rerun();
                } else {
                    st.error(f"❌ Backend error: {response.status_code}");
                    try {
                        st.json(response.json());
                    } except Exception {
                        st.text(response.text);
                    }
                }
            }
        } except Exception as e {
            terminal_lines.append(f'❌ Error: {str(e)}');
            terminal_output.code('\n'.join(terminal_lines), language='');
            
            let error_msg = str(e);
            if ('Timeout' in error_msg or 'timeout' in error_msg) {
                st.error('⏱️ Request timeout. The repository might be too large or network is slow.');
                st.info('💡 Try:\n- A smaller repository\n- Check your internet connection\n- Try again (sometimes GitHub rate limits)');
            } elif ('Connection' in error_msg) {
                st.error('🔌 Cannot connect to backend. Ensure backend is running on http://localhost:8000');
                st.code('jac serve main.jac', language='bash');
            } else {
                st.error(f'❌ Error: {error_msg}');
                st.exception(e);
            }
        }
    }
    
    # Display last analysis if available
    if (st.session_state.last_analysis) {
        let analysis = st.session_state.last_analysis;
        
        # Check for error
        if ('error' in analysis) {
            st.error(f"❌ Analysis Error: {analysis['error']}");
            st.stop();
        }
        
        # Display summary
        st.markdown('---');
        st.subheader('📋 Analysis Summary');
        
        # Show LLM Response first if available
        if 'llm_response' in analysis {
            with st.expander('🤖 Initial LLM Analysis', expanded=False) {
                st.markdown(analysis['llm_response']);
            }
        }
        
        let cols = st.columns(3);
        with cols[0] {
            st.metric("Repository", analysis.get('repo_info', {}).get('repo', 'N/A'));
        }
        with cols[1] {
            let total_files = analysis.get('docgenie', {}).get('structure', {}).get('total_files', 0);
            st.metric("Total Files", total_files);
        }
        with cols[2] {
            let lang_count = len(analysis.get('codeanalyzer', {}).get('languages', {}));
            st.metric("Languages", lang_count);
        }
        
        # Create tabs
        let (tab1, tab2, tab3, tab4, tab5) = st.tabs([
            '🗺️ RepoMapper',
            '🛠️ CodeAnalyzer',
            '📖 Documentation',
            '🕸️ Diagrams',
            '📊 Raw Data'
        ]);
        
        with tab1 {
            st.markdown('### 🗺️ Repository Mapping Results');
            
            let repomapper = analysis.get('repomapper', {});
            
            st.markdown('#### 🔍 URL Validation');
            let validation = repomapper.get('validation', 'N/A');
            st.markdown(f"<div class='info-box'>{validation}</div>", unsafe_allow_html=True);
            
            st.markdown('#### 🗂️ Structure Analysis');
            let structure_analysis = repomapper.get('structure_analysis', 'N/A');
            st.markdown(structure_analysis);
            
            st.markdown('#### 📄 README Summary');
            let readme_summary = repomapper.get('readme_summary', 'No README found');
            st.markdown(readme_summary);
            
            with st.expander('📖 View README Content (First 500 chars)') {
                let readme_full = repomapper.get('readme_full', 'No content available');
                st.code(readme_full, language='markdown');
            }
        }
        
        with tab2 {
            st.markdown('### 🛠️ Code Analysis Results');
            
            let codeanalyzer = analysis.get('codeanalyzer', {});
            
            st.markdown('#### 📊 Programming Languages Distribution');
            let languages = codeanalyzer.get('languages', {});
            
            if languages {
                # Create bar chart
                st.bar_chart(languages);
                
                # Display as table - Simple sorting without lambda
                st.markdown('**Language Breakdown:**');
                let lang_df = [];
                # Convert to list and create sortable tuples (percentage, language)
                let sortable_list = [];
                for lang in languages {
                    sortable_list.append((languages[lang], lang));
                }
                # Sort and reverse for descending order
                sortable_list.sort();
                sortable_list.reverse();
                # Build the display list
                for item in sortable_list {
                    let percentage = item[0];
                    let lang = item[1];
                    lang_df.append({'Language': lang, 'Percentage': f'{percentage}%'});
                }
                st.table(lang_df);
            } else {
                st.info('No language data available.');
            }
            
            st.markdown('#### 🔍 Languages Analysis');
            let lang_analysis = codeanalyzer.get('languages_analysis', 'N/A');
            st.markdown(lang_analysis);
            
            st.markdown('#### 💡 Suggested Improvements');
            let improvements = codeanalyzer.get('improvements', 'N/A');
            st.markdown(improvements);
        }
        
        with tab3 {
            st.markdown('### 📖 Generated Documentation');
            
            let docgenie = analysis.get('docgenie', {});
            let documentation = docgenie.get('documentation', 'No documentation generated');
            
            st.markdown(documentation);
            
            # File structure
            with st.expander('📁 Repository Structure Details') {
                let structure = docgenie.get('structure', {});
                st.json(structure);
            }
        }
        
        with tab4 {
            st.markdown('### 🕸️ Visual Diagrams');
            
            let docgenie = analysis.get('docgenie', {});
            let mermaid_data = docgenie.get('mermaid', {});
            
            if mermaid_data {
                st.markdown('#### 🏗️ Architecture Diagram');
                let architecture = mermaid_data.get('architecture', '');
                
                if architecture {
                    st.code(architecture, language='mermaid');
                    
                    st.markdown('**Rendered Diagram:**');
                    st.markdown(f"```mermaid\n{architecture}\n```");
                } else {
                    st.info('No architecture diagram available.');
                }
            } else {
                st.info('No diagram data available.');
            }
        }
        
        with tab5 {
            st.markdown('### 📊 Complete Analysis Data');
            st.json(analysis);
            
            # Download option
            let json_str = json.dumps(analysis, indent=2);
            st.download_button(
                label='⬇️ Download Analysis Report (JSON)',
                data=json_str,
                file_name=f"analysis_{analysis.get('repo_info', {}).get('repo', 'report')}.json",
                mime='application/json'
            );
        }
    } else {
        st.info('👆 Enter a GitHub repository URL above and click "Analyze Repository" to begin.');
    }
}