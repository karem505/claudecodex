#!/usr/bin/env bash
# claudecodex installer.
#
#   curl -fsSL https://raw.githubusercontent.com/karem505/claudecodex/main/install.sh | bash
#
# Installs the `claudecodex` launcher to ~/.local/bin and checks prerequisites.
# It does NOT install the proxy or log you in (those need your interaction) —
# it prints the exact commands if they're missing.
#
# Env:
#   CLAUDECODEX_INSTALL_DIR   where to install the launcher (default: ~/.local/bin)
#   CLAUDECODEX_REF           git ref/branch to pull from   (default: main)
set -euo pipefail

REPO="karem505/claudecodex"
REF="${CLAUDECODEX_REF:-main}"
RAW="https://raw.githubusercontent.com/${REPO}/${REF}"
INSTALL_DIR="${CLAUDECODEX_INSTALL_DIR:-$HOME/.local/bin}"

blue()  { printf '\033[0;34m==>\033[0m %s\n' "$1"; }
green() { printf '\033[0;32m==>\033[0m %s\n' "$1"; }
yellow(){ printf '\033[0;33m !\033[0m %s\n' "$1"; }

blue "Installing claudecodex to ${INSTALL_DIR}"
mkdir -p "$INSTALL_DIR"

if command -v curl >/dev/null 2>&1; then
  curl -fsSL "${RAW}/claudecodex" -o "${INSTALL_DIR}/claudecodex"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "${INSTALL_DIR}/claudecodex" "${RAW}/claudecodex"
else
  echo "Need curl or wget to install." >&2; exit 1
fi
chmod +x "${INSTALL_DIR}/claudecodex"
green "Launcher installed: ${INSTALL_DIR}/claudecodex"

# Ensure the install dir is on PATH (add to the right shell rc if not).
case ":${PATH}:" in
  *":${INSTALL_DIR}:"*) : ;;
  *)
    case "${SHELL:-}" in *zsh) rc="$HOME/.zshrc" ;; *) rc="$HOME/.bashrc" ;; esac
    if ! grep -qs "claudecodex install dir" "$rc" 2>/dev/null; then
      printf '\n# claudecodex install dir\nexport PATH="%s:$PATH"\n' "$INSTALL_DIR" >> "$rc"
      yellow "Added ${INSTALL_DIR} to PATH in ${rc} — open a new terminal or: source ${rc}"
    fi
    ;;
esac

echo ""
blue "Checking prerequisites"

if command -v claude >/dev/null 2>&1; then
  green "Claude Code found: $(claude --version 2>/dev/null | head -1)"
else
  yellow "Claude Code ('claude') not found. Install it: https://claude.com/claude-code"
fi

if command -v claude-code-proxy >/dev/null 2>&1; then
  green "Proxy found: $(claude-code-proxy --version 2>/dev/null | head -1)"
  if claude-code-proxy codex auth status >/dev/null 2>&1; then
    green "Codex auth: logged in"
  else
    yellow "Codex not authenticated. Run:  claude-code-proxy codex auth login"
  fi
else
  yellow "Proxy 'claude-code-proxy' not found. Install it, then log in:"
  echo "     curl -fsSL https://raw.githubusercontent.com/raine/claude-code-proxy/main/scripts/install.sh | bash"
  echo "     claude-code-proxy codex auth login"
fi

echo ""
green "Done. Start it with:  claudecodex"
echo "     claudecodex --mini   # use gpt-5.4-mini for this session"
echo "     See:  https://github.com/${REPO}"
