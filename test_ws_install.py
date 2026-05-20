#!/usr/bin/env python3
try:
    import websocket
    print("websocket OK")
except ImportError:
    print("websocket not installed")
