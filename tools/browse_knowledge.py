#!/usr/bin/env python3
# code:tool-browse-knowledge-001:fetch-web-content
"""
Browse Knowledge Tool — Fetch content from a web knowledge base via CDP.

Connects to an existing Chrome/Chromium browser on CDP port 9222,
navigates to the target URL, and extracts the rendered text content.

Uses ONLY Python standard library (no pip install required).

Usage:
    python tools/browse_knowledge.py
    python tools/browse_knowledge.py --search "docker"
    python tools/browse_knowledge.py --url "https://example.com" --cdp-port 9222
"""
# code:tool-browse-knowledge-002:imports
import argparse
import json
import sys
import time
import urllib.request
import urllib.error
import struct
import hashlib
import base64
import socket
import os
import ssl

CDP_HOST = "localhost"
CDP_PORT = 9222
DEFAULT_URL = (
    "https://rbxappinsight.gscfin.com/"
    "?root=RBXInsightBot"
    "&path=DOCKER-MARKDOWN-BROWSER-SOLUTION.md"
    "&focusId=plan%3Aarchitecture%3Adetail-0010"
)


# code:tool-browse-knowledge-003:cdp-connection
def get_cdp_tabs(port):
    """Get list of browser tabs from CDP endpoint."""
    try:
        req = urllib.request.urlopen(f"http://{CDP_HOST}:{port}/json", timeout=5)
        return json.loads(req.read().decode())
    except urllib.error.URLError as e:
        print(f"ERROR: Cannot connect to CDP on port {port}. "
              f"Ensure Chrome is running with --remote-debugging-port={port}",
              file=sys.stderr)
        print(f"Detail: {e}", file=sys.stderr)
        sys.exit(1)


def find_target_tab(tabs, url=None):
    """Find the best tab to use — matching URL or first page tab."""
    # First, try to find an exact URL match
    if url:
        for tab in tabs:
            tab_url = tab.get("url", "")
            if url.split("?")[0] in tab_url:
                return tab

    # Fallback: first tab with type "page"
    for tab in tabs:
        if tab.get("type") == "page":
            return tab

    # Last resort: first tab
    return tabs[0] if tabs else None


# code:tool-browse-knowledge-004:websocket-stdlib
class SimpleWebSocket:
    """Minimal WebSocket client using only Python stdlib."""

    def __init__(self, url):
        parsed = urllib.request.urlparse(url)
        self.host = parsed.hostname
        self.port = parsed.port or (443 if parsed.scheme == "wss" else 80)
        self.path = parsed.path or "/"

        self.sock = socket.create_connection((self.host, self.port), timeout=15)
        if parsed.scheme == "wss":
            ctx = ssl.create_default_context()
            self.sock = ctx.wrap_socket(self.sock, server_hostname=self.host)

        # WebSocket handshake
        key = base64.b64encode(os.urandom(16)).decode()
        handshake = (
            f"GET {self.path} HTTP/1.1\r\n"
            f"Host: {self.host}:{self.port}\r\n"
            f"Upgrade: websocket\r\n"
            f"Connection: Upgrade\r\n"
            f"Sec-WebSocket-Key: {key}\r\n"
            f"Sec-WebSocket-Version: 13\r\n"
            f"\r\n"
        )
        self.sock.sendall(handshake.encode())

        # Read handshake response
        response = b""
        while b"\r\n\r\n" not in response:
            chunk = self.sock.recv(4096)
            if not chunk:
                raise ConnectionError("WebSocket handshake failed")
            response += chunk

        if b"101" not in response.split(b"\r\n")[0]:
            raise ConnectionError(f"WebSocket handshake rejected: {response[:200]}")

    def send(self, data):
        """Send a text frame."""
        payload = data.encode("utf-8")
        frame = bytearray()
        frame.append(0x81)  # FIN + text opcode

        # Mask key
        mask_key = os.urandom(4)

        length = len(payload)
        if length < 126:
            frame.append(0x80 | length)  # MASK bit set
        elif length < 65536:
            frame.append(0x80 | 126)
            frame.extend(struct.pack(">H", length))
        else:
            frame.append(0x80 | 127)
            frame.extend(struct.pack(">Q", length))

        frame.extend(mask_key)
        masked = bytearray(b ^ mask_key[i % 4] for i, b in enumerate(payload))
        frame.extend(masked)

        self.sock.sendall(frame)

    def recv(self, timeout=30):
        """Receive a text frame."""
        self.sock.settimeout(timeout)
        data = self._recv_bytes(2)
        opcode = data[0] & 0x0F
        masked = (data[1] & 0x80) != 0
        length = data[1] & 0x7F

        if length == 126:
            length = struct.unpack(">H", self._recv_bytes(2))[0]
        elif length == 127:
            length = struct.unpack(">Q", self._recv_bytes(8))[0]

        if masked:
            mask_key = self._recv_bytes(4)

        payload = self._recv_bytes(length)

        if masked:
            payload = bytearray(b ^ mask_key[i % 4] for i, b in enumerate(payload))

        if opcode == 0x1:  # text
            return payload.decode("utf-8")
        elif opcode == 0x8:  # close
            return None
        else:
            return payload.decode("utf-8", errors="replace")

    def _recv_bytes(self, count):
        """Read exactly `count` bytes."""
        buf = bytearray()
        while len(buf) < count:
            chunk = self.sock.recv(count - len(buf))
            if not chunk:
                raise ConnectionError("Connection closed")
            buf.extend(chunk)
        return bytes(buf)

    def close(self):
        """Close the connection."""
        try:
            self.sock.close()
        except Exception:
            pass


# code:tool-browse-knowledge-005:cdp-evaluate
def cdp_evaluate(ws, expression, timeout=15):
    """Send a Runtime.evaluate CDP command and return the value."""
    import random
    msg_id = random.randint(1, 100000)
    cmd = json.dumps({
        "id": msg_id,
        "method": "Runtime.evaluate",
        "params": {"expression": expression, "returnByValue": True}
    })
    ws.send(cmd)

    deadline = time.time() + timeout
    while time.time() < deadline:
        raw = ws.recv(timeout=max(1, deadline - time.time()))
        if raw is None:
            return None
        msg = json.loads(raw)
        if msg.get("id") == msg_id:
            result = msg.get("result", {}).get("result", {})
            return result.get("value", "")
    return None


def cdp_navigate(ws, url, timeout=15):
    """Navigate to a URL via CDP."""
    import random
    msg_id = random.randint(1, 100000)
    cmd = json.dumps({
        "id": msg_id,
        "method": "Page.navigate",
        "params": {"url": url}
    })
    ws.send(cmd)

    deadline = time.time() + timeout
    while time.time() < deadline:
        raw = ws.recv(timeout=max(1, deadline - time.time()))
        if raw is None:
            return
        msg = json.loads(raw)
        if msg.get("id") == msg_id:
            return


# code:tool-browse-knowledge-006:fetch-content
def fetch_page_content(target_url, cdp_port, search_term=None):
    """Main logic: connect to CDP, navigate if needed, extract content."""
    tabs = get_cdp_tabs(cdp_port)
    tab = find_target_tab(tabs, target_url)

    if not tab:
        print("ERROR: No suitable browser tab found.", file=sys.stderr)
        sys.exit(1)

    ws_url = tab.get("webSocketDebuggerUrl")
    if not ws_url:
        print("ERROR: No WebSocket URL for the tab.", file=sys.stderr)
        sys.exit(1)

    tab_url = tab.get("url", "")
    needs_navigation = target_url.split("?")[0] not in tab_url

    ws = SimpleWebSocket(ws_url)

    try:
        # Navigate if the tab is not already on the target URL
        if needs_navigation:
            print(f"Navigating to: {target_url}", file=sys.stderr)
            cdp_navigate(ws, target_url)
            time.sleep(3)
        else:
            print(f"Tab already on target URL: {tab.get('title', 'unknown')}", file=sys.stderr)

        # Extract text content
        content = cdp_evaluate(ws, "document.body.innerText")

        if not content:
            print("WARNING: body.innerText empty, trying textContent...", file=sys.stderr)
            content = cdp_evaluate(ws, "document.body.textContent")

        if not content:
            print("ERROR: Could not extract any text content from the page.", file=sys.stderr)
            sys.exit(1)

        # Filter by search term if provided
        if search_term:
            lines = content.split("\n")
            relevant = []
            for i, line in enumerate(lines):
                if search_term.lower() in line.lower():
                    start = max(0, i - 3)
                    end = min(len(lines), i + 4)
                    chunk = lines[start:end]
                    relevant.extend(chunk)
                    relevant.append("---")

            if relevant:
                return "\n".join(relevant)
            else:
                return f"NOT_FOUND: No content matching '{search_term}' on this page."

        return content

    finally:
        ws.close()


# code:tool-browse-knowledge-007:main-cli
def main():
    parser = argparse.ArgumentParser(
        description="Fetch content from a web knowledge base via CDP browser."
    )
    parser.add_argument(
        "--url",
        default=DEFAULT_URL,
        help="URL to navigate to (default: RBXInsightBot knowledge base)"
    )
    parser.add_argument(
        "--search",
        default=None,
        help="Optional search term to filter relevant content"
    )
    parser.add_argument(
        "--cdp-port",
        type=int,
        default=CDP_PORT,
        help=f"CDP port (default: {CDP_PORT})"
    )

    args = parser.parse_args()
    content = fetch_page_content(args.url, args.cdp_port, args.search)
    print(content)


if __name__ == "__main__":
    main()
