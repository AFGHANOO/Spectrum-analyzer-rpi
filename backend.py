#!/usr/bin/env python3
"""
RPi4 Spectrum Analyzer - WebSocket Backend
Designed By M Jafari
------------------------------------------
Reads real spectrum data from RTL-SDR via pyrtlsdr,
computes FFT, and streams to the browser dashboard via WebSocket.

Requirements:
  pip3 install pyrtlsdr numpy flask flask-socketio flask-cors eventlet
"""

import numpy as np
import threading
import time
import json
from flask import Flask, send_from_directory
from flask_socketio import SocketIO, emit
from flask_cors import CORS

app = Flask(__name__, static_folder='.')
CORS(app)
sio = SocketIO(app, cors_allowed_origins='*', async_mode='eventlet')

# ── Configuration (updated live from browser) ──────────────────────────────
config = {
    'center_freq': 433.92e6,   # Hz
    'sample_rate': 2.4e6,      # Hz
    'gain':        30,         # dB  (0 = auto)
    'fft_size':    1024,
    'sweep_ms':    50,
}

running = True
sdr = None

def init_sdr():
    """Initialize RTL-SDR device."""
    global sdr
    try:
        from rtlsdr import RtlSdr
        sdr = RtlSdr()
        sdr.sample_rate = config['sample_rate']
        sdr.center_freq = config['center_freq']
        sdr.gain        = config['gain']
        print(f"[SDR] Device opened — CF={config['center_freq']/1e6:.3f} MHz  SR={config['sample_rate']/1e6:.2f} MS/s")
        return True
    except Exception as e:
        print(f"[SDR] Could not open device: {e}")
        print("[SDR] Running in DEMO mode (simulated spectrum)")
        return False

def gen_demo_spectrum(cf, sr, n):
    """Fallback: generate simulated spectrum when no SDR is attached."""
    noise_floor = -90
    sp = np.random.normal(noise_floor, 1.5, n)
    signals = [
        {'offset': 0.0,   'amp': 48, 'bw': 0.012},
        {'offset': -0.19, 'amp': 24, 'bw': 0.006},
        {'offset':  0.26, 'amp': 38, 'bw': 0.016},
        {'offset': -0.36, 'amp': 16, 'bw': 0.004},
        {'offset':  0.43, 'amp': 30, 'bw': 0.009},
    ]
    for s in signals:
        bc  = int(n * (0.5 + s['offset']))
        bwb = s['bw'] * n
        for i in range(-int(bwb * 5), int(bwb * 5) + 1):
            b = bc + i
            if 0 <= b < n:
                v = s['amp'] * np.exp(-(i * i) / (2 * bwb * bwb))
                if sp[b] < noise_floor + v:
                    sp[b] = noise_floor + v
    return sp.tolist()

def sweep_loop():
    """Main acquisition loop — runs in background thread."""
    global sdr
    has_sdr = init_sdr()
    while running:
        try:
            n   = config['fft_size']
            cf  = config['center_freq']
            sr  = config['sample_rate']

            if has_sdr and sdr:
                # Apply live config changes
                if sdr.center_freq != cf:
                    sdr.center_freq = cf
                if sdr.sample_rate != sr:
                    sdr.sample_rate = sr
                if sdr.gain != config['gain']:
                    sdr.gain = config['gain']

                # Read samples and compute FFT
                samples = sdr.read_samples(n * 4)
                window  = np.blackman(len(samples))
                fft_out = np.fft.fftshift(np.fft.fft(samples * window, n))
                psd     = 10 * np.log10(np.abs(fft_out[:n]) ** 2 + 1e-12)
            else:
                psd = gen_demo_spectrum(cf, sr, n)

            sio.emit('spectrum', {
                'psd':  psd if isinstance(psd, list) else psd.tolist(),
                'cf':   cf / 1e6,
                'sr':   sr / 1e6,
                'n':    n,
            })

        except Exception as e:
            print(f"[SWEEP] Error: {e}")

        time.sleep(config['sweep_ms'] / 1000.0)

@sio.on('set_config')
def set_config(data):
    """Browser → server: update SDR parameters live."""
    if 'center_freq' in data:
        config['center_freq'] = float(data['center_freq']) * 1e6
    if 'sample_rate' in data:
        config['sample_rate'] = float(data['sample_rate']) * 1e6
    if 'gain' in data:
        config['gain'] = float(data['gain'])
    if 'sweep_ms' in data:
        config['sweep_ms'] = int(data['sweep_ms'])
    if 'fft_size' in data:
        config['fft_size'] = int(data['fft_size'])
    print(f"[CONFIG] Updated: CF={config['center_freq']/1e6:.3f} MHz  Gain={config['gain']} dB")

@app.route('/')
def index():
    return send_from_directory('.', 'spectrum_analyzer.html')

@sio.on('connect')
def on_connect():
    print('[WS] Browser connected')

@sio.on('disconnect')
def on_disconnect():
    print('[WS] Browser disconnected')

if __name__ == '__main__':
    print("=" * 55)
    print("  RPi4 Spectrum Analyzer — Backend Server")
    print("  Designed By M Jafari")
    print("=" * 55)
    print(f"  Open browser at:  http://raspberrypi.local:5000")
    print(f"  Or locally:       http://localhost:5000")
    print("=" * 55)
    t = threading.Thread(target=sweep_loop, daemon=True)
    t.start()
    sio.run(app, host='0.0.0.0', port=5000, debug=False)
