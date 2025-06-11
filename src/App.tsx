import React, { useState } from 'react';
import {
  Shield,
  GitBranch,
  FileText,
  Settings,
  Code,
  CheckCircle,
  AlertTriangle,
  Eye,
  Database,
  Cloud,
  ArrowRight,
  Github,
  Play,
  Download,
  Lock
} from 'lucide-react';

interface Tool {
  name: string;
  icon: React.ReactNode;
  description: string;
  format: string;
  color: string;
}

interface WorkflowStep {
  title: string;
  description: string;
  icon: React.ReactNode;
  code?: string;
}

function App() {
  const [activeTab, setActiveTab] = useState<'overview' | 'workflows' | 'structure' | 'implementation'>('overview');

  const tools: Tool[] = [
    {
      name: 'Trivy',
      icon: <Shield className="w-6 h-6" />,
      description: 'Analyse des vulnérabilités et secrets',
      format: 'SARIF',
      color: 'bg-blue-500'
    },
    {
      name: 'Checkov',
      icon: <CheckCircle className="w-6 h-6" />,
      description: 'Analyse de configuration IaC',
      format: 'SARIF',
      color: 'bg-green-500'
    },
    {
      name: 'SonarQube',
      icon: <Code className="w-6 h-6" />,
      description: 'Qualité et sécurité du code',
      format: 'Dashboard Web',
      color: 'bg-orange-500'
    }
  ];

  const workflowSteps: WorkflowStep[] = [
    {
      title: 'Analyse du Code',
      description: 'Exécution des outils de sécurité sur le code source',
      icon: <Play className="w-5 h-5" />,
      code: `- name: Run Trivy filesystem scan
  run: trivy fs . --scanners vuln,secret --format github --output trivy_results.sarif`
    },
    {
      title: 'Génération des Rapports',
      description: 'Création des fichiers SARIF pour GitHub Code Scanning',
      icon: <FileText className="w-5 h-5" />,
      code: `- name: Upload SARIF report
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: trivy_results.sarif`
    },
    {
      title: 'Centralisation',
      description: 'Stockage et visualisation dans GitHub Security',
      icon: <Database className="w-5 h-5" />,
      code: `# Résultats visibles dans Security > Code scanning alerts`
    }
  ];

  const trivyWorkflow = `name: Trivy Security Scan
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  trivy:
    runs-on: ubuntu-latest
    permissions:
      security-events: write
      contents: read
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Run Trivy filesystem scan
      id: trivy
      run: |
        trivy fs . --scanners vuln,secret \\
          --format github --output trivy_results.sarif
      continue-on-error: true
    
    - name: Upload Trivy SARIF report
      uses: github/codeql-action/upload-sarif@v3
      with:
        sarif_file: trivy_results.sarif
      if: always()`;

  const checkovWorkflow = `name: Checkov IaC Security Scan
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  checkov:
    runs-on: ubuntu-latest
    permissions:
      security-events: write
      contents: read
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Run Checkov scan
      id: checkov
      uses: bridgecrewio/checkov-action@master
      with:
        output_format: sarif
        output_file_path: checkov_results.sarif
        quiet: true
        soft_fail: true
    
    - name: Upload Checkov SARIF report
      uses: github/codeql-action/upload-sarif@v3
      with:
        sarif_file: checkov_results.sarif
      if: always()`;

  const repoStructure = `security-scan-reports/
├── README.md
├── trivy_reports/
│   ├── trivy_report_abc123.sarif
│   ├── trivy_report_def456.sarif
│   └── latest_trivy_report.sarif
├── checkov_reports/
│   ├── checkov_report_abc123.sarif
│   ├── checkov_report_def456.sarif
│   └── latest_checkov_report.sarif
├── consolidated_reports/
│   ├── security_summary_2024-01.json
│   └── security_dashboard.html
└── scripts/
    ├── generate_summary.py
    └── upload_to_s3.sh`;

  const consolidationScript = `# Étape additionnelle pour centraliser dans un dépôt dédié
- name: Push reports to central repository
  if: always()
  run: |
    git config --global user.email "github-actions[bot]@users.noreply.github.com"
    git config --global user.name "github-actions[bot]"
    
    # Clone du dépôt central
    git clone https://github.com/\${{ github.repository_owner }}/security-scan-reports.git
    cd security-scan-reports
    
    # Création du dossier par outil
    mkdir -p trivy_reports checkov_reports
    
    # Copie des rapports avec timestamp
    cp ../trivy_results.sarif trivy_reports/trivy_\${{ github.sha }}.sarif
    cp ../checkov_results.sarif checkov_reports/checkov_\${{ github.sha }}.sarif
    
    # Commit et push
    git add .
    git commit -m "Security reports for \${{ github.sha }}" || echo "No changes"
    git push https://x-access-token:\${{ secrets.REPO_ACCESS_TOKEN }}@github.com/\${{ github.repository_owner }}/security-scan-reports.git`;

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-50">
      {/* Header */}
      <header className="bg-white/80 backdrop-blur-md border-b border-slate-200 sticky top-0 z-50">
        <div className="container mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="bg-gradient-to-r from-blue-600 to-indigo-600 p-2 rounded-lg">
                <Shield className="w-6 h-6 text-white" />
              </div>
              <div>
                <h1 className="text-xl font-bold text-slate-800">Security Analysis Hub</h1>
                <p className="text-sm text-slate-600">Centralisation des analyses de sécurité</p>
              </div>
            </div>
            <div className="flex items-center space-x-2 text-sm text-slate-600">
              <Github className="w-4 h-4" />
              <span>GitHub Integration</span>
            </div>
          </div>
        </div>
      </header>

      {/* Navigation */}
      <nav className="bg-white/60 backdrop-blur-sm border-b border-slate-200">
        <div className="container mx-auto px-6">
          <div className="flex space-x-8">
            {[
              { id: 'overview', label: 'Vue d\'ensemble', icon: <Eye className="w-4 h-4" /> },
              { id: 'workflows', label: 'Workflows', icon: <GitBranch className="w-4 h-4" /> },
              { id: 'structure', label: 'Structure', icon: <Database className="w-4 h-4" /> },
              { id: 'implementation', label: 'Implémentation', icon: <Settings className="w-4 h-4" /> }
            ].map(tab => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                className={`flex items-center space-x-2 py-4 px-2 border-b-2 transition-colors ${
                  activeTab === tab.id
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-slate-600 hover:text-slate-800'
                }`}
              >
                {tab.icon}
                <span className="font-medium">{tab.label}</span>
              </button>
            ))}
          </div>
        </div>
      </nav>

      <main className="container mx-auto px-6 py-8">
        {activeTab === 'overview' && (
          <div className="space-y-8">
            {/* Tools Overview */}
            <section className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
              <h2 className="text-2xl font-bold text-slate-800 mb-4 flex items-center">
                <Shield className="w-6 h-6 mr-3 text-blue-600" />
                Outils d'Analyse de Sécurité
              </h2>
              <div className="grid md:grid-cols-3 gap-6">
                {tools.map((tool, index) => (
                  <div key={index} className="bg-gradient-to-br from-white to-slate-50 rounded-lg p-5 border border-slate-200 hover:shadow-md transition-shadow">
                    <div className="flex items-center mb-3">
                      <div className={`${tool.color} p-2 rounded-lg text-white mr-3`}>
                        {tool.icon}
                      </div>
                      <h3 className="font-semibold text-slate-800">{tool.name}</h3>
                    </div>
                    <p className="text-slate-600 text-sm mb-3">{tool.description}</p>
                    <div className="flex items-center text-xs text-slate-500">
                      <FileText className="w-3 h-3 mr-1" />
                      Format: {tool.format}
                    </div>
                  </div>
                ))}
              </div>
            </section>

            {/* Workflow Process */}
            <section className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
              <h2 className="text-2xl font-bold text-slate-800 mb-6 flex items-center">
                <GitBranch className="w-6 h-6 mr-3 text-green-600" />
                Processus de Centralisation
              </h2>
              <div className="flex flex-col md:flex-row items-center justify-between space-y-4 md:space-y-0 md:space-x-4">
                {workflowSteps.map((step, index) => (
                  <React.Fragment key={index}>
                    <div className="flex-1 bg-gradient-to-br from-blue-50 to-indigo-50 rounded-lg p-4 border border-blue-200">
                      <div className="flex items-center mb-2">
                        <div className="bg-blue-100 p-2 rounded text-blue-600 mr-3">
                          {step.icon}
                        </div>
                        <h3 className="font-semibold text-slate-800">{step.title}</h3>
                      </div>
                      <p className="text-sm text-slate-600 mb-3">{step.description}</p>
                      {step.code && (
                        <code className="text-xs bg-slate-800 text-green-400 p-2 rounded block overflow-x-auto">
                          {step.code}
                        </code>
                      )}
                    </div>
                    {index < workflowSteps.length - 1 && (
                      <ArrowRight className="w-5 h-5 text-slate-400 hidden md:block" />
                    )}
                  </React.Fragment>
                ))}
              </div>
            </section>

            {/* Benefits */}
            <section className="bg-gradient-to-r from-green-50 to-emerald-50 rounded-xl border border-green-200 p-6">
              <h2 className="text-2xl font-bold text-slate-800 mb-4 flex items-center">
                <CheckCircle className="w-6 h-6 mr-3 text-green-600" />
                Avantages de la Centralisation
              </h2>
              <div className="grid md:grid-cols-2 gap-4">
                {[
                  'Interface GitHub Security intégrée',
                  'Historique des analyses de sécurité',
                  'Alertes automatiques sur les vulnérabilités',
                  'Rapports SARIF standardisés',
                  'Intégration native avec les pull requests',
                  'Tableau de bord unifié pour tous les outils'
                ].map((benefit, index) => (
                  <div key={index} className="flex items-center text-slate-700">
                    <CheckCircle className="w-4 h-4 text-green-500 mr-2 flex-shrink-0" />
                    <span className="text-sm">{benefit}</span>
                  </div>
                ))}
              </div>
            </section>
          </div>
        )}

        {activeTab === 'workflows' && (
          <div className="space-y-8">
            <section className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
              <h2 className="text-2xl font-bold text-slate-800 mb-6 flex items-center">
                <GitBranch className="w-6 h-6 mr-3 text-blue-600" />
                Workflows GitHub Actions
              </h2>
              
              <div className="space-y-8">
                <div>
                  <h3 className="text-lg font-semibold text-slate-800 mb-3 flex items-center">
                    <Shield className="w-5 h-5 mr-2 text-blue-500" />
                    Trivy Security Scan
                  </h3>
                  <div className="bg-slate-900 rounded-lg p-4 overflow-x-auto">
                    <pre className="text-sm text-green-400">
                      <code>{trivyWorkflow}</code>
                    </pre>
                  </div>
                </div>

                <div>
                  <h3 className="text-lg font-semibold text-slate-800 mb-3 flex items-center">
                    <CheckCircle className="w-5 h-5 mr-2 text-green-500" />
                    Checkov IaC Scan
                  </h3>
                  <div className="bg-slate-900 rounded-lg p-4 overflow-x-auto">
                    <pre className="text-sm text-green-400">
                      <code>{checkovWorkflow}</code>
                    </pre>
                  </div>
                </div>
              </div>
            </section>

            <section className="bg-amber-50 rounded-xl border border-amber-200 p-6">
              <div className="flex items-start">
                <AlertTriangle className="w-5 h-5 text-amber-600 mr-3 mt-0.5 flex-shrink-0" />
                <div>
                  <h3 className="font-semibold text-amber-800 mb-2">Note importante</h3>
                  <p className="text-sm text-amber-700">
                    Les permissions <code className="bg-amber-100 px-1 rounded">security-events: write</code> sont 
                    nécessaires pour uploader les rapports SARIF vers GitHub Code Scanning.
                  </p>
                </div>
              </div>
            </section>
          </div>
        )}

        {activeTab === 'structure' && (
          <div className="space-y-8">
            <section className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
              <h2 className="text-2xl font-bold text-slate-800 mb-6 flex items-center">
                <Database className="w-6 h-6 mr-3 text-purple-600" />
                Structure du Dépôt de Rapports
              </h2>
              
              <div className="bg-slate-900 rounded-lg p-6">
                <pre className="text-sm text-green-400 overflow-x-auto">
                  <code>{repoStructure}</code>
                </pre>
              </div>
            </section>

            <section className="grid md:grid-cols-2 gap-6">
              <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
                <h3 className="text-lg font-semibold text-slate-800 mb-4 flex items-center">
                  <Github className="w-5 h-5 mr-2 text-slate-600" />
                  GitHub Code Scanning
                </h3>
                <div className="space-y-3 text-sm text-slate-600">
                  <div className="flex items-center">
                    <CheckCircle className="w-4 h-4 text-green-500 mr-2" />
                    Interface intégrée dans GitHub
                  </div>
                  <div className="flex items-center">
                    <CheckCircle className="w-4 h-4 text-green-500 mr-2" />
                    Alertes automatiques
                  </div>
                  <div className="flex items-center">
                    <CheckCircle className="w-4 h-4 text-green-500 mr-2" />
                    Intégration PR/Reviews
                  </div>
                  <div className="flex items-center">
                    <CheckCircle className="w-4 h-4 text-green-500 mr-2" />
                    Format SARIF standardisé
                  </div>
                </div>
              </div>

              <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
                <h3 className="text-lg font-semibold text-slate-800 mb-4 flex items-center">
                  <Cloud className="w-5 h-5 mr-2 text-orange-500" />
                  SonarQube Dashboard
                </h3>
                <div className="space-y-3 text-sm text-slate-600">
                  <div className="flex items-center">
                    <CheckCircle className="w-4 h-4 text-green-500 mr-2" />
                    Dashboard web dédié
                  </div>
                  <div className="flex items-center">
                    <CheckCircle className="w-4 h-4 text-green-500 mr-2" />
                    Métriques détaillées
                  </div>
                  <div className="flex items-center">
                    <CheckCircle className="w-4 h-4 text-green-500 mr-2" />
                    Historique temporel
                  </div>
                  <div className="flex items-center">
                    <CheckCircle className="w-4 h-4 text-green-500 mr-2" />
                    Règles personnalisables
                  </div>
                </div>
              </div>
            </section>
          </div>
        )}

        {activeTab === 'implementation' && (
          <div className="space-y-8">
            <section className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
              <h2 className="text-2xl font-bold text-slate-800 mb-6 flex items-center">
                <Settings className="w-6 h-6 mr-3 text-indigo-600" />
                Implémentation Avancée
              </h2>
              
              <div className="space-y-6">
                <div>
                  <h3 className="text-lg font-semibold text-slate-800 mb-3 flex items-center">
                    <Download className="w-5 h-5 mr-2 text-blue-500" />
                    Centralisation dans un Dépôt Dédié
                  </h3>
                  <div className="bg-slate-900 rounded-lg p-4 overflow-x-auto">
                    <pre className="text-sm text-green-400">
                      <code>{consolidationScript}</code>
                    </pre>
                  </div>
                </div>

                <div className="bg-blue-50 rounded-lg border border-blue-200 p-6">
                  <h4 className="font-semibold text-blue-800 mb-3 flex items-center">
                    <Lock className="w-4 h-4 mr-2" />
                    Configuration des Secrets
                  </h4>
                  <div className="space-y-2 text-sm text-blue-700">
                    <p><strong>REPO_ACCESS_TOKEN:</strong> Personal Access Token avec droits d'écriture</p>
                    <p><strong>Permissions requises:</strong> Contents (write), Metadata (read)</p>
                    <p><strong>Stockage:</strong> Settings → Secrets and variables → Actions</p>
                  </div>
                </div>
              </div>
            </section>

            <section className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
              <h3 className="text-lg font-semibold text-slate-800 mb-4">
                Recommandations de Mise en Œuvre
              </h3>
              <div className="grid md:grid-cols-2 gap-6">
                <div className="space-y-4">
                  <h4 className="font-medium text-slate-800 flex items-center">
                    <CheckCircle className="w-4 h-4 text-green-500 mr-2" />
                    Approche Recommandée
                  </h4>
                  <ul className="space-y-2 text-sm text-slate-600 ml-6">
                    <li>• Utiliser GitHub Code Scanning pour Trivy/Checkov</li>
                    <li>• Garder SonarQube sur son dashboard dédié</li>
                    <li>• Archiver les rapports comme artefacts de workflow</li>
                    <li>• Configurer des notifications automatiques</li>
                  </ul>
                </div>
                <div className="space-y-4">
                  <h4 className="font-medium text-slate-800 flex items-center">
                    <AlertTriangle className="w-4 h-4 text-amber-500 mr-2" />
                    Points d'Attention
                  </h4>
                  <ul className="space-y-2 text-sm text-slate-600 ml-6">
                    <li>• Gérer les permissions des PAT soigneusement</li>
                    <li>• Éviter la duplication des rapports</li>
                    <li>• Nettoyer régulièrement les anciens rapports</li>
                    <li>• Monitorer l'usage des quotas GitHub Actions</li>
                  </ul>
                </div>
              </div>
            </section>
          </div>
        )}
      </main>
    </div>
  );
}

export default App;