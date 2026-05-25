# RPi4 Spectrum Analyzer — Complete Setup Guide
## RTL-SDR Blog V3 + Raspberry Pi 4
### Designed By M Jafari

---

## HARDWARE REQUIRED

| Item | Specification |
|------|--------------|
| Raspberry Pi 4 | 2GB minimum, 4GB recommended |
| RTL-SDR Blog V3 | RTL2832U + R820T2, 1PPM TCXO, SMA |
| Antenna | SMA telescopic dipole or band antenna |
| MicroSD Card | 32GB+ Class 10 (Samsung / SanDisk) |
| Power Supply | 5V / 3A USB-C (official RPi PSU) |
| Network | WiFi or Ethernet to your router |

### Optional Accessories
| Item | Benefit |
|------|---------|
| Nooelec LaNA LNA | +10–15 dB sensitivity, better weak signal |
| 433 MHz SAW filter | Cleaner ISM 433 band, less interference |
| 900 MHz SAW filter | Cleaner 900 MHz monitoring |
| RPi heatsink + fan | Keeps CPU cool during continuous use |

---

## QUICK INSTALL (3 commands after SSH)

```bash
scp spectrum_analyzer_rpi4_v2.zip pi@raspberrypi.local:/home/pi/
ssh pi@raspberrypi.local
cd /home/pi && unzip spectrum_analyzer_rpi4_v2.zip && cd spectrum_analyzer_project && bash install.sh
```

---

## STEP-BY-STEP INSTALLATION

---

### PHASE 1 — FLASH RASPBERRY PI OS

#### Step 1 — Download Raspberry Pi Imager
Visit: https://www.raspberrypi.com/software/
Download and install Raspberry Pi Imager for your OS.

#### Step 2 — Flash the SD Card
1. Insert microSD into your computer
2. Open Raspberry Pi Imager
3. Click **Choose Device** → **Raspberry Pi 4**
4. Click **Choose OS** → **Raspberry Pi OS (other)**
   → **Raspberry Pi OS Lite (64-bit)**
5. Click **Choose Storage** → select your SD card
6. Click the **⚙ gear icon** (Advanced Options):
   - ✅ **Enable SSH** → Use password authentication
   - ✅ **Username:** `pi`
   - ✅ **Password:** choose a strong password
   - ✅ **Configure WiFi** → enter your network SSID + password
   - ✅ **Set locale and timezone** to your region
7. Click **Save** → **Write**
8. Wait for writing + verification (~5 minutes)

#### Step 3 — First Boot
1. Insert SD card into Raspberry Pi 4
2. Connect power (do NOT connect RTL-SDR yet)
3. Wait 60–90 seconds for first boot to complete
4. Verify connectivity:
```bash
ping raspberrypi.local
```

---

### PHASE 2 — CONNECT TO THE PI

#### Step 4 — SSH into the Pi
**Windows** — Open PowerShell:
```bash
ssh pi@raspberrypi.local
```
**Mac / Linux** — Open Terminal:
```bash
ssh pi@raspberrypi.local
```
Type `yes` when asked about fingerprint.
Enter your password when prompted.

If `.local` doesn't resolve, find the IP from your router's
DHCP table and use `ssh pi@192.168.1.XXX` instead.

#### Step 5 — Update the System
```bash
sudo apt update && sudo apt upgrade -y
sudo reboot
```
Wait 30 seconds, then SSH back in:
```bash
ssh pi@raspberrypi.local
```

---

### PHASE 3 — TRANSFER PROJECT FILES

#### Step 6 — Copy ZIP to the Pi
**On your computer**, open a terminal/PowerShell in the folder
where you saved `spectrum_analyzer_rpi4_v2.zip`:

```bash
scp spectrum_analyzer_rpi4_v2.zip pi@raspberrypi.local:/home/pi/
```
Enter your Pi password when prompted.

#### Step 7 — Extract the ZIP on the Pi
**Back on the Pi (via SSH):**
```bash
cd /home/pi
unzip spectrum_analyzer_rpi4_v2.zip
cd spectrum_analyzer_project
ls -la
```

You should see these files:
```
install.sh
start.sh
backend.py
spectrum_analyzer.html
requirements.txt
spectrum-analyzer.service
SETUP_GUIDE.md
```

---

### PHASE 4 — RUN THE INSTALLER

#### Step 8 — Run install.sh
```bash
bash install.sh
```

This script automatically performs all 8 installation steps:

| Step | What it does |
|------|-------------|
| 1/8 | Checks system is a Raspberry Pi |
| 2/8 | Updates all system packages |
| 3/8 | Installs rtl-sdr, librtlsdr-dev, python3-pip, build tools |
| 4/8 | Blacklists conflicting DVB kernel driver |
| 5/8 | Sets USB device permissions via udev rules |
| 6/8 | Installs Python packages (pyrtlsdr, flask, flask-socketio) |
| 7/8 | Copies project files to /home/pi/spectrum_analyzer/ |
| 8/8 | Installs + enables systemd auto-start service |

**Expected final output:**
```
═══════════════════════════════════════════════════════
   ✓ INSTALLATION COMPLETE!
═══════════════════════════════════════════════════════

   1. Plug in your RTL-SDR Blog V3 dongle
   2. Open browser on any device on your WiFi
   3. Go to: http://raspberrypi.local:5000
```

---

### PHASE 5 — CONNECT RTL-SDR AND TEST

#### Step 9 — Plug In the RTL-SDR V3
Connect the RTL-SDR Blog V3 dongle to any USB port on the Pi.
Wait 5 seconds.

#### Step 10 — Test the Device
```bash
rtl_test -t
```

**Expected output:**
```
Found 1 device(s):
  0:  Realtek, RTL2838UHIDIR, SN: 00000001
Using device 0: Generic RTL2832U OEM
Found Rafael Micro R820T tuner
Supported gain values (29): 0.0 1.0 2.0 3.7 ... 49.6
Sampling at 2048000 S/s.
```
✅ If you see **"Found 1 device"** — your RTL-SDR is working.

**If you see "No supported devices found":**
```bash
sudo modprobe -r dvb_usb_rtl28xxu
rtl_test -t
```

---

### PHASE 6 — OPEN THE DASHBOARD

#### Step 11 — Start the Server (manual)
```bash
bash /home/pi/spectrum_analyzer/start.sh
```

#### Step 12 — Open in Browser
On **any device** (phone, tablet, laptop) on the **same WiFi**:

```
http://raspberrypi.local:5000
```

If that doesn't work, use IP address:
```bash
# Find your Pi's IP:
hostname -I
```
Then go to: `http://YOUR_PI_IP:5000`

Your spectrum analyzer dashboard loads with live RTL-SDR data! 🎉

---

### PHASE 7 — AUTO-START (Already done by install.sh)

The installer already set up the systemd service.
The server starts automatically on every boot.

**Verify the service is running:**
```bash
sudo systemctl status spectrum-analyzer
```
Look for: `Active: active (running)`

**Service management commands:**
```bash
sudo systemctl start   spectrum-analyzer   # start
sudo systemctl stop    spectrum-analyzer   # stop
sudo systemctl restart spectrum-analyzer   # restart
sudo systemctl disable spectrum-analyzer   # disable auto-start
sudo systemctl enable  spectrum-analyzer   # enable auto-start
journalctl -u spectrum-analyzer -f         # view live logs
```

---

## DASHBOARD CONTROLS REFERENCE

### Frequency Controls
| Control | Range | Notes |
|---------|-------|-------|
| Center Frequency | 0.5–900 MHz | Type MHz, press Enter |
| Span | 100 kHz–500 MHz | Zooms around center frequency |
| Start / Stop | Auto-calculated | Shown below CF input |

### Amplitude Controls
| Control | Range | Notes |
|---------|-------|-------|
| Ref Level | −120 to 0 dBm | Top of display scale |
| Scale | 1–20 dB/div | Vertical zoom |

### RF Controls
| Control | Notes |
|---------|-------|
| Gain | 0–49 dB. Start at 30, reduce if overloaded |
| AGC | Auto gain control toggle |
| LNA | External LNA toggle (informational) |
| BIAS-T | Powers LNA through coax (+4.5V on RTL-SDR V3) |

### Noise Controls
| Control | Notes |
|---------|-------|
| Floor Level | −120 to −50 dBm — raises/lowers noise floor |
| Noise Variance | 0.2–8 dB — tightens or spreads noise band |

### Detection Modes
| Mode | Effect |
|------|--------|
| NORM | Normal real-time trace |
| PEAK | Peak hold — shows maximum seen |
| AVG  | 8-frame average — smooths noise |

### Markers
| Action | Result |
|--------|--------|
| Left-click spectrum | Place M1 (yellow marker) |
| Right-click spectrum | Place M2 (cyan marker) |
| Type MHz in M1 field + Enter | Jump M1 to frequency |
| Type MHz in M2 field + Enter | Jump M2 to frequency |
| PEAK↑ (M1) | Auto-find strongest signal → M1 |
| PEAK↑ (M2) | Auto-find 2nd strongest signal → M2 |
| Δ Freq display | Frequency difference between M1 and M2 |
| Δ Level display | Amplitude difference in dB |

### View Modes
| Mode | Notes |
|------|-------|
| 2D Spectrum | Yellow trace, black background |
| 3D Perspective | Isometric stacked waterfall history |

### Frequency Presets
| Preset | Frequency | Common Use |
|--------|-----------|------------|
| 433 ISM | 433.92 MHz | Wireless sensors, key fobs, remotes |
| 868 ISM | 868 MHz | LoRa, Zigbee (Europe) |
| 900 ISM | 900 MHz | LoRa (US), DECT phones |
| FM | 88.5 MHz | FM broadcast band |
| NOAA | 162.4 MHz | US weather radio |
| PMR446 | 446 MHz | License-free walkie-talkies |

---

## TROUBLESHOOTING

### "No supported devices found"
The DVB driver is still loaded. Run:
```bash
sudo modprobe -r dvb_usb_rtl28xxu
rtl_test -t
```
If still failing, reboot the Pi with the dongle plugged in:
```bash
sudo reboot
```

### "Permission denied" accessing USB device
```bash
sudo usermod -aG plugdev pi
# Log out and back in, then try again
```

### Dashboard shows DEMO MODE (simulated data)
The backend cannot find the RTL-SDR device.
Check the service log for the exact error:
```bash
journalctl -u spectrum-analyzer -f
```

### Frequency readings are slightly off
Calibrate your dongle's PPM crystal error:
```bash
rtl_test -p
# Wait 10 minutes, note the PPM value
```
Then edit `/home/pi/spectrum_analyzer/backend.py` and add:
```python
sdr.freq_correction = 4   # replace 4 with your PPM value
```
Restart the service:
```bash
sudo systemctl restart spectrum-analyzer
```

### Pi runs hot (CPU > 75°C)
```bash
vcgencmd measure_temp
```
Add a heatsink and fan. The 3D perspective view is more
CPU intensive — use 2D mode for lower power consumption.

### Can't reach raspberrypi.local from browser
On Windows you may need Bonjour installed for mDNS resolution.
Use the IP address directly instead:
```bash
# On the Pi:
hostname -I
# Then in browser: http://192.168.1.XXX:5000
```

### RTL-SDR dongle very hot
Normal — the R820T2 tuner chip runs warm. Ensure there is
airflow around the dongle. Do not place inside an enclosure.

### Dashboard freezes or lags
Reduce sweep rate (increase sweep interval slider).
Use 2D mode instead of 3D.
Close unused browser tabs.
Check Pi CPU load: `top`

---

## QUICK REFERENCE COMMANDS

```bash
# Test RTL-SDR detection
rtl_test -t

# List USB devices
lsusb | grep Realtek

# Start server manually
bash /home/pi/spectrum_analyzer/start.sh

# Service control
sudo systemctl status  spectrum-analyzer
sudo systemctl start   spectrum-analyzer
sudo systemctl stop    spectrum-analyzer
sudo systemctl restart spectrum-analyzer

# View live logs
journalctl -u spectrum-analyzer -f

# Check CPU temperature
vcgencmd measure_temp

# Check Pi IP address
hostname -I

# Calibrate PPM offset
rtl_test -p

# Scan for signals (command line)
rtl_power -f 430M:440M:10k -g 30 -i 1 output.csv
```

---

## PROJECT FILE STRUCTURE

```
/home/pi/spectrum_analyzer/
├── spectrum_analyzer.html    ← Dashboard (served to browser)
├── backend.py                ← WebSocket server + RTL-SDR reader
└── start.sh                  ← Manual start script

/etc/systemd/system/
└── spectrum-analyzer.service ← Auto-start on boot

/etc/modprobe.d/
└── blacklist-rtlsdr.conf     ← DVB driver blacklist

/etc/udev/rules.d/
└── rtl-sdr.rules             ← USB device permissions
```

---

*RPi4 Spectrum Analyzer Project*
*Designed By M Jafari*
