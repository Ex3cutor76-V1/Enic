#!/usr/bin/env bash

set -e

# Cores

VERMELHO=$'\033[31m'
VERDE=$'\033[32m'
AMARELO=$'\033[33m'
RESET=$'\033[0m'

# Variáveis importantes

NOME="enic"
PREFIXO="/opt/enic"
BIN="/usr/local/bin"
DESKTOP="/usr/share/applications"

# Verificação Root

if [ "$EUID" -ne 0 ]; then
    printf "${VERMELHO}Erro: execute como root.${RESET}\n"
    echo "Use: sudo ./install.sh"
    exit 1
fi

# Localização do diretório do projeto

DIRETORIO_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Verificação de dependências

if ! command -v perl >/dev/null 2>&1; then
    printf "${VERMELHO}Erro: Perl não está instalado.${RESET}\n"
    exit 1
fi

if ! perl -MGtk3 -e 1 >/dev/null 2>&1; then
    printf "${VERMELHO}Erro: módulo Perl Gtk3 não encontrado.${RESET}\n"
    printf "Instale com: sudo apt install libgtk3-perl\n"
    exit 1
fi

if ! perl -MGlib::Object::Introspection -e 1 >/dev/null 2>&1; then
    printf "${VERMELHO}Erro: módulo Perl Glib::Object::Introspection não encontrado.${RESET}\n"
    printf "Instale com: sudo apt install libglib-object-introspection-perl\n"
    exit 1
fi

if ! perl -Mlib="$DIRETORIO_SCRIPT/lib" -MEnic::Terminal -e 1 >/dev/null 2>&1; then
    printf "${VERMELHO}Erro: Vte ou Pango não encontrados.${RESET}\n"
    printf "Instale com: sudo apt install libvte-2.91-0 gir1.2-vte-2.91 gir1.2-pango-1.0\n"
    exit 1
fi

printf "${AMARELO}Instalando Enic...${RESET}\n"
echo "Origem: $DIRETORIO_SCRIPT"
echo "Destino: $PREFIXO"

# Criação de diretórios

mkdir -p "$PREFIXO"
mkdir -p "$BIN"
mkdir -p "$DESKTOP"

# Cópia dos arquivos do Enic

cp "$DIRETORIO_SCRIPT/enic" \
   "$PREFIXO/enic"

# Biblotéca perl

rm -rf "$PREFIXO/lib"

cp -r "$DIRETORIO_SCRIPT/lib" \
      "$PREFIXO/lib"

# Permissões do arquivo

chmod 755 "$PREFIXO/enic"

# Launcher

cat > "$BIN/enic" <<'EOF'
#!/bin/bash

exec /opt/enic/enic "$@"
EOF

chmod 755 "$BIN/enic"

# Criação de .desktop

cat > "$DESKTOP/enic.desktop" <<'EOF'
[Desktop Entry]
Name=Enic
Comment=Terminal Emulator
Exec=/usr/local/bin/enic
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=System;TerminalEmulator;
StartupNotify=true
EOF

chmod 644 "$DESKTOP/enic.desktop"

# Finalização de instalação

echo
printf "${VERDE}Enic instalado com sucesso!${RESET}\n"
echo
echo "Executável: /usr/local/bin/enic"
echo "Arquivos:   /opt/enic"
echo "Desktop:    /usr/share/applications/enic.desktop"
echo
echo "Execute:"
echo "    enic"

echo
echo "Enic instalado com sucesso!"
echo

# Auto exclusão

if [ "$DIRETORIO_SCRIPT" != "$PREFIXO" ]; then
    rm -rf "$DIRETORIO_SCRIPT"
fi

printf "${VERDE}Arquivos temporários removidos.${RESET}\n"
