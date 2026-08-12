# ============================================================
# ENIC - Configuração do prompt
# ============================================================

export ENIC_TERMINAL=1

# ------------------------------------------------------------
# Carrega o .bashrc do usuário
# ------------------------------------------------------------

if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc"
fi

# ------------------------------------------------------------
# Guarda o PS1 definido pelo usuário
# ------------------------------------------------------------

ENIC_ORIGINAL_PS1="$PS1"

# ------------------------------------------------------------
# Cores do Enic
# ------------------------------------------------------------

ENIC_USER='\[\e[38;5;245m\]'
ENIC_HOST='\[\e[38;5;240m\]'
ENIC_PATH='\[\e[38;5;24m\]'
ENIC_RESET='\[\e[0m\]'

# ------------------------------------------------------------
# Se não existir PS1, usa um padrão simples
# ------------------------------------------------------------

if [ -z "$ENIC_ORIGINAL_PS1" ]; then
    ENIC_ORIGINAL_PS1='\u@\h:\w\$ '
fi

# ------------------------------------------------------------
# Aplica as cores do Enic
#
# Substituímos apenas os escapes:
#
#   \u  usuário
#   \h  hostname
#   \w  diretório
#
# O Bash continua responsável por expandi-los.
# ------------------------------------------------------------

PS1="${ENIC_ORIGINAL_PS1//\\u/$ENIC_USER\\u$ENIC_RESET}"
PS1="${PS1//\\h/$ENIC_HOST\\h$ENIC_RESET}"
PS1="${PS1//\\w/$ENIC_PATH\\w$ENIC_RESET}"

export PS1
