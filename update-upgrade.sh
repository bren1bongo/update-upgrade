#!/bin/bash
# dnf_update.sh — Update & upgrade DNF packages on Fedora 44

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helpers
info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Root check - Reqires root
if [[ $EUID -ne 0 ]]; then
  error "This script must be run as root (use sudo)."
  exit 1
fi

echo -e "\n${CYAN}======================================${NC}"
echo -e "${CYAN}   Brendan's 44 — DNF Update & Upgrade  ${NC}"
echo -e "${CYAN}======================================${NC}\n"

# 1. Refresh metadata
info "Refreshing package metadata..."
dnf makecache --refresh -y
success "Metadata refreshed."

# 2. Apply all updates
info "Applying package updates..."
if dnf upgrade --refresh -y; then
  success "All packages updated successfully."
else
  error "DNF upgrade encountered an error."
  exit 1
fi

# 3. Remove system orphaned dependencies
info "Removing unused dependencies (autoremove)..."
dnf autoremove -y
success "Orphaned packages removed."

# 4. Clean up system  cached data
info "Cleaning DNF cache..."
dnf clean packages -y
success "Cache cleaned."

# 5. Summary
echo -e "\n${GREEN}All done! Your Fedora 44 system is up to date.${NC}"

# Optional: prompts admin for reboot if kernel was updated
LAST_KERNEL=$(rpm -q kernel --last | head -1 | awk '{print $1}')
RUNNING_KERNEL="kernel-$(uname -r)"

if [[ "$LAST_KERNEL" != "$RUNNING_KERNEL" ]]; then
  warn "A new kernel was installed (${LAST_KERNEL})."
  warn "A reboot is recommended to apply the new kernel."
  read -rp "Reboot now? [y/N] " answer
  if [[ "${answer,,}" == "y" ]]; then
    info "Rebooting..."
    reboot
  else
    info "Reboot skipped. Remember to reboot later."
  fi
else
  success "Running kernel is already up to date — no reboot needed."
fi

echo ""
