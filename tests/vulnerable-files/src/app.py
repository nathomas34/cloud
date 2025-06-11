import os
import sqlite3
from flask import Flask, request, jsonify, render_template_string

app = Flask(__name__)

# Vulnérabilités: Secrets codés en dur
SECRET_KEY = 'super-secret-flask-key'
DATABASE_PASSWORD = 'admin123'
API_TOKEN = 'sk-1234567890abcdef'

app.secret_key = SECRET_KEY

# Vulnérabilité: Configuration de debug en production
app.config['DEBUG'] = True

@app.route('/user/<user_id>')
def get_user(user_id):
    """Vulnérabilité: SQL Injection"""
    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()
    
    # Vulnérabilité: Requête SQL non sécurisée
    query = f"SELECT * FROM users WHERE id = {user_id}"
    cursor.execute(query)
    
    result = cursor.fetchone()
    conn.close()
    
    return jsonify({'user': result, 'query': query})

@app.route('/search')
def search():
    """Vulnérabilité: XSS (Cross-Site Scripting)"""
    search_term = request.args.get('q', '')
    
    # Vulnérabilité: Pas d'échappement HTML
    template = f"<h1>Résultats pour: {search_term}</h1>"
    return render_template_string(template)

@app.route('/upload', methods=['POST'])
def upload_file():
    """Vulnérabilité: Upload de fichiers non sécurisé"""
    if 'file' not in request.files:
        return jsonify({'error': 'No file'}), 400
    
    file = request.files['file']
    
    # Vulnérabilité: Pas de validation du type de fichier
    # Vulnérabilité: Pas de limitation de taille
    filename = file.filename
    file.save(f'/tmp/{filename}')  # Vulnérabilité: Path traversal possible
    
    return jsonify({'message': f'File {filename} uploaded'})

@app.route('/exec')
def execute_command():
    """Vulnérabilité: Injection de commandes"""
    cmd = request.args.get('cmd', 'ls')
    
    # Vulnérabilité: Exécution de commandes utilisateur
    import subprocess
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    
    return jsonify({
        'command': cmd,
        'output': result.stdout,
        'error': result.stderr
    })

@app.route('/debug')
def debug_info():
    """Vulnérabilité: Exposition d'informations sensibles"""
    return jsonify({
        'environment': dict(os.environ),
        'secrets': {
            'secret_key': SECRET_KEY,
            'db_password': DATABASE_PASSWORD,
            'api_token': API_TOKEN
        },
        'config': {
            'debug': app.config['DEBUG'],
            'secret_key': app.secret_key
        }
    })

@app.route('/deserialize', methods=['POST'])
def deserialize_data():
    """Vulnérabilité: Désérialisation non sécurisée"""
    import pickle
    import base64
    
    data = request.json.get('data', '')
    
    try:
        # Vulnérabilité: Désérialisation de données utilisateur
        decoded = base64.b64decode(data)
        result = pickle.loads(decoded)
        return jsonify({'result': str(result)})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/redirect')
def redirect_user():
    """Vulnérabilité: Open Redirect"""
    url = request.args.get('url', '/')
    
    # Vulnérabilité: Redirection non validée
    from flask import redirect
    return redirect(url)

# Vulnérabilité: Pas de protection CSRF
@app.route('/admin/delete/<item_id>', methods=['GET', 'POST'])
def delete_item(item_id):
    """Vulnérabilité: CSRF et autorisation insuffisante"""
    # Pas de vérification d'authentification
    # Pas de protection CSRF
    return jsonify({'message': f'Item {item_id} deleted'})

if __name__ == '__main__':
    # Vulnérabilité: Serveur accessible depuis toutes les interfaces
    app.run(host='0.0.0.0', port=5000, debug=True)