#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#  RPi4 Spectrum Analyzer — Start Script
#  Designed By M Jafari
# ═══════════════════════════════════════════════════════════════

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
NC='\033[0m'

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${WHITE}   ◈ RPi4 Spectrum Analyzer — Starting...${NC}"
echo -e "${CYAN}   Designed By M Jafari${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""

# Unload conflicting DVB driver if loaded
if lsmod | grep -q dvb_usb_rtl28xxu; then
  echo -e "${YELLOW}  Unloading conflicting DVB driver...${NC}"
  sudo modprobe -r dvb_usb_rtl28xxu 2>/dev/null || true
fi

# Check RTL-SDR is connected
if rtl_test -t 2>&1 | grep -q "Found 1 device"; then
  echo -e "${GREEN}  ✓ RTL-SDR Blog V3 detected${NC}"
else
  echo -e "${YELLOW}  ⚠  RTL-SDR not detected — running in DEMO mode${NC}"
fi

# Get IP address
IP=$(hostname -I | awk '{print $1}')
echo ""
echo -e "${WHITE}  Dashboard URL:${NC}"
echo -e "  ${CYAN}http://raspberrypi.local:5000${NC}"
echo -e "  ${CYAN}http://${IP}:5000${NC}"
echo ""
echo -e "  Press Ctrl+C to stop"
echo ""

cd "$(dirname "$0")"
python3 backend.py
