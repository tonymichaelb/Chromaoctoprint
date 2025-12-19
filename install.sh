#!/bin/bash
set -e

echo "=========================================="
echo "   Instalador do Chroma (OctoPrint)"
echo "=========================================="
echo ""

# 1. Clonar/atualizar repositório
echo "[1/6] Clonando/atualizando repositório..."
cd ~
if [ ! -d "Chromaoctoprint" ]; then
    git clone https://github.com/tonymichaelb/Chromaoctoprint.git
    cd Chromaoctoprint
else
    cd Chromaoctoprint
    git pull origin main
fi
echo "✓ Repositório atualizado"
echo ""

# 2. Criar venv e instalar dependências
echo "[2/6] Criando ambiente virtual e instalando dependências..."
python3 -m venv ~/octoprint-venv
~/octoprint-venv/bin/pip install --upgrade pip setuptools wheel > /dev/null 2>&1
~/octoprint-venv/bin/pip install -e ~/Chromaoctoprint > /dev/null 2>&1
echo "✓ Chroma instalado"
echo ""

# 3. Criar configuração
echo "[3/6] Configurando Chroma..."
mkdir -p ~/.octoprint
if [ ! -f ~/.octoprint/config.yaml ]; then
    cat > ~/.octoprint/config.yaml <<EOF
server:
  host: 0.0.0.0
  port: 5000
EOF
    echo "✓ Arquivo de configuração criado"
else
    echo "✓ Arquivo de configuração já existe"
fi
echo ""

# 4. Instalar serviço systemd
echo "[4/6] Instalando serviço systemd..."
sudo tee /etc/systemd/system/octoprint.service > /dev/null <<'SYSTEMD'
[Unit]
Description=Chroma Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=pi
Group=pi
Environment=LC_ALL=C.UTF-8
Environment=LANG=C.UTF-8
WorkingDirectory=/home/pi
ExecStart=/home/pi/octoprint-venv/bin/chroma serve --host=0.0.0.0 --port=5000
Restart=on-failure
Nice=5

[Install]
WantedBy=multi-user.target
SYSTEMD
echo "✓ Serviço systemd instalado"
echo ""

# 5. Compilar tradução pt_BR
echo "[5/6] Instalando gettext e compilando tradução pt_BR..."
sudo apt-get update > /dev/null 2>&1
sudo apt-get install -y gettext > /dev/null 2>&1

cd ~/Chromaoctoprint/src/octoprint/translations/pt_BR/LC_MESSAGES
if ! msgfmt messages.po -o messages.mo 2>/dev/null; then
    echo "  Corrigindo duplicatas em messages.po..."
    msguniq messages.po -o messages.dedup.po
    msgfmt messages.dedup.po -o messages.mo
    rm messages.dedup.po
fi

TRANS_DIR="$(~/octoprint-venv/bin/python -c 'import os,octoprint; print(os.path.join(os.path.dirname(octoprint.__file__), "translations", "pt_BR", "LC_MESSAGES"))')"
sudo mkdir -p "$TRANS_DIR"
sudo cp messages.mo "$TRANS_DIR/messages.mo"
echo "✓ Tradução pt_BR compilada e instalada"
echo ""

# 6. Iniciar serviço
echo "[6/6] Iniciando Chroma..."
sudo systemctl daemon-reload
sudo systemctl enable octoprint > /dev/null 2>&1
sudo systemctl start octoprint
sleep 2

echo ""
echo "=========================================="
echo "   ✓ CHROMA INSTALADO COM SUCESSO!"
echo "=========================================="
echo ""
echo "Status do serviço:"
sudo systemctl status --no-pager octoprint
echo ""
echo "Acesse Chroma em:"
echo "  → http://<seu-ip-do-pi>:5000"
echo "  → http://chroma.local:5000 (se mDNS estiver ativo)"
echo ""
echo "Para ativar português (Brasil):"
echo "  1. Acesse a interface web"
echo "  2. Settings → Appearance → Language → Português (Brasil)"
echo "  3. Clique Save e recarregue (Ctrl+Shift+R)"
echo ""
echo "Para ver logs:"
echo "  sudo journalctl -u octoprint -f"
echo ""
echo "Para reiniciar:"
echo "  sudo systemctl restart octoprint"
echo ""
