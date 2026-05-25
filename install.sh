#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#  RPi4 Spectrum Analyzer — Full Installation Script
#  RTL-SDR Blog V3 + Raspberry Pi 4
#  Designed By M Jafari
# ═══════════════════════════════════════════════════════════════

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

INSTALL_DIR="/home/pi/spectrum_analyzer"

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${WHITE}   ◈ RPi4 Spectrum Analyzer — Installation Script${NC}"
echo -e "${WHITE}   RTL-SDR Blog V3 + Raspberry Pi 4${NC}"
echo -e "${CYAN}   Designed By M Jafari${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""

# ── STEP 1: Check we are on a Raspberry Pi ──────────────────
echo -e "${YELLOW}[STEP 1/8]${NC} Checking system..."
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null && ! grep -q "raspberrypi" /etc/hostname 2>/dev/null; then
  echo -e "${YELLOW}  ⚠  Warning: This does not appear to be a Raspberry Pi.${NC}"
  echo -e "     Installation will continue but RTL-SDR may not work."
else
  echo -e "${GREEN}  ✓ Raspberry Pi detected${NC}"
fi

# ── STEP 2: System update ───────────────────────────────────
echo ""
echo -e "${YELLOW}[STEP 2/8]${NC} Updating system packages..."
sudo apt update -qq
sudo apt upgrade -y -qq
echo -e "${GREEN}  ✓ System updated${NC}"

# ── STEP 3: Install system dependencies ─────────────────────
echo ""
echo -e "${YELLOW}[STEP 3/8]${NC} Installing RTL-SDR system packages..."
sudo apt install -y -qq \
  rtl-sdr \
  librtlsdr-dev \
  git \
  build-essential \
  cmake \
  python3-pip \
  python3-numpy \
  udev
echo -e "${GREEN}  ✓ System packages installed${NC}"

# ── STEP 4: Blacklist DVB kernel driver ─────────────────────
echo ""
echo -e "${YELLOW}[STEP 4/8]${NC} Blacklisting conflicting DVB kernel driver..."
sudo tee /etc/modprobe.d/blacklist-rtlsdr.conf > /dev/null << 'EOF'
blacklist dvb_usb_rtl28xxu
blacklist rtl2832
blacklist rtl2830
EOF
sudo modprobe -r dvb_usb_rtl28xxu 2>/dev/null || true
sudo modprobe -r rtl2832 2>/dev/null || true
sudo update-initramfs -u -q 2>/dev/null || true
echo -e "${GREEN}  ✓ DVB driver blacklisted${NC}"

# ── STEP 5: USB permissions (udev rules) ────────────────────
echo ""
echo -e "${YELLOW}[STEP 5/8]${NC} Setting USB device permissions..."
sudo tee /etc/udev/rules.d/rtl-sdr.rules > /dev/null << 'EOF'
SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2832", GROUP="plugdev", MODE="0666", SYMLINK+="rtl_sdr"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2838", GROUP="plugdev", MODE="0666", SYMLINK+="rtl_sdr"
EOF
sudo usermod -aG plugdev pi 2>/dev/null || true
sudo udevadm control --reload-rules
sudo udevadm trigger
echo -e "${GREEN}  ✓ USB permissions configured${NC}"

# ── STEP 6: Install Python packages ─────────────────────────
echo ""
echo -e "${YELLOW}[STEP 6/8]${NC} Installing Python packages..."
pip3 install --break-system-packages \
  pyrtlsdr \
  flask \
  flask-socketio \
  flask-cors \
  eventlet 2>/dev/null || \
pip3 install \
  pyrtlsdr \
  flask \
  flask-socketio \
  flask-cors \
  eventlet
echo -e "${GREEN}  ✓ Python packages installed${NC}"

# ── STEP 7: Copy project files ──────────────────────────────
echo ""
echo -e "${YELLOW}[STEP 7/8]${NC} Installing project files to ${INSTALL_DIR}..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sudo mkdir -p "$INSTALL_DIR"
sudo cp "$SCRIPT_DIR/spectrum_analyzer.html" "$INSTALL_DIR/"
sudo cp "$SCRIPT_DIR/backend.py"             "$INSTALL_DIR/"
sudo cp "$SCRIPT_DIR/start.sh"               "$INSTALL_DIR/"
sudo chmod +x "$INSTALL_DIR/start.sh"
sudo chown -R pi:pi "$INSTALL_DIR"
echo -e "${GREEN}  ✓ Project files installed to ${INSTALL_DIR}${NC}"

# ── STEP 8: Install systemd service ─────────────────────────
echo ""
echo -e "${YELLOW}[STEP 8/8]${NC} Installing auto-start service..."
sudo cp "$SCRIPT_DIR/spectrum-analyzer.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable spectrum-analyzer
sudo systemctl start spectrum-analyzer
sleep 2
STATUS=$(sudo systemctl is-active spectrum-analyzer)
if [ "$STATUS" = "active" ]; then
  echo -e "${GREEN}  ✓ Service installed and running${NC}"
else
  echo -e "${YELLOW}  ⚠  Service installed but not yet active (plug in RTL-SDR dongle and reboot)${NC}"
fi

# ── DONE ────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   ✓ INSTALLATION COMPLETE!${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${WHITE}   1. Plug in your RTL-SDR Blog V3 dongle${NC}"
echo -e "${WHITE}   2. Open browser on any device on your WiFi${NC}"
echo -e "${WHITE}   3. Go to:${NC} ${CYAN}http://raspberrypi.local:5000${NC}"
echo ""
echo -e "${YELLOW}   If .local doesn't work, find your Pi IP with:${NC}"
echo -e "   hostname -I"
echo -e "   Then go to: http://YOUR_IP:5000"
echo ""
echo -e "${YELLOW}   Useful commands:${NC}"
echo -e "   sudo systemctl status spectrum-analyzer   # check status"
echo -e "   sudo systemctl restart spectrum-analyzer  # restart"
echo -e "   journalctl -u spectrum-analyzer -f        # view logs"
echo -e "   rtl_test -t                               # test RTL-SDR"
echo ""
