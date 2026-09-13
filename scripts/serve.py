#!/usr/bin/env python3
import http.server
import socket
import socketserver
import os
import sys

PORT = 8080
BUILD_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "build"))
TIPA_NAME = "LowBatCountdown-1.0.3.tipa"

def get_local_ip():
    try:
        import subprocess
        for iface in ["en0", "en1"]:
            res = subprocess.run(["ipconfig", "getifaddr", iface], capture_output=True, text=True)
            ip = res.stdout.strip()
            if res.returncode == 0 and ip:
                return ip
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

def generate_index_html(ip):
    tipa_url = f"http://{ip}:{PORT}/{TIPA_NAME}"
    troll_url = f"apple-magnifier://install?url={tipa_url}"
    
    html = f"""<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>低电量倒计时 - TrollStore 一键安装</title>
    <style>
        * {{ box-sizing: border-box; margin: 0; padding: 0; }}
        body {{
            background: #0f1117;
            color: #f0f3f6;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 24px;
        }}
        .card {{
            background: rgba(26, 31, 46, 0.85);
            border: 1px solid rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(20px);
            -webkit-backdrop-filter: blur(20px);
            border-radius: 24px;
            padding: 32px 24px;
            max-width: 400px;
            width: 100%;
            text-align: center;
            box-shadow: 0 16px 40px rgba(0, 0, 0, 0.5);
        }}
        .badge {{
            display: inline-block;
            background: rgba(255, 59, 48, 0.15);
            color: #ff453a;
            border: 1px solid rgba(255, 59, 48, 0.3);
            border-radius: 20px;
            padding: 4px 12px;
            font-size: 13px;
            font-weight: 600;
            margin-bottom: 16px;
        }}
        h1 {{
            font-size: 24px;
            font-weight: 700;
            margin-bottom: 8px;
        }}
        p.sub {{
            font-size: 14px;
            color: #8b949e;
            margin-bottom: 24px;
            line-height: 1.5;
        }}
        .btn {{
            display: block;
            width: 100%;
            padding: 16px;
            border-radius: 14px;
            font-size: 16px;
            font-weight: 600;
            text-decoration: none;
            cursor: pointer;
            transition: all 0.2s ease;
            margin-bottom: 12px;
        }}
        .btn-primary {{
            background: #ff453a;
            color: #ffffff;
            box-shadow: 0 4px 14px rgba(255, 69, 58, 0.4);
        }}
        .btn-primary:active {{
            transform: scale(0.98);
            background: #e03b30;
        }}
        .btn-secondary {{
            background: rgba(255, 255, 255, 0.08);
            color: #c9d1d9;
        }}
        .btn-secondary:active {{
            background: rgba(255, 255, 255, 0.15);
        }}
        .hint {{
            font-size: 12px;
            color: #6e7681;
            margin-top: 16px;
            line-height: 1.4;
        }}
    </style>
</head>
<body>
    <div class="card">
        <div class="badge">iOS 15.0 - 16.6.1 · TrollStore</div>
        <h1>低电量倒计时</h1>
        <p class="sub">版本 1.0.3 · 局域网开发版</p>
        
        <a class="btn btn-primary" href="{troll_url}">🚀 唤起 TrollStore 直接安装</a>
        <a class="btn btn-secondary" href="/{TIPA_NAME}">⬇️ 直接下载 .tipa 安装包</a>

        <div class="hint">
            页面将自动尝试通过 <code>apple-magnifier://</code> 协议呼起手机上的 TrollStore。若未自动弹出，请点击上方红色按钮。
        </div>
    </div>
    <script>
        window.addEventListener("DOMContentLoaded", function() {{
            setTimeout(function() {{
                window.location.href = "{troll_url}";
            }}, 300);
        }});
    </script>
</body>
</html>
"""
    with open(os.path.join(BUILD_DIR, "index.html"), "w", encoding="utf-8") as f:
        f.write(html)

class CustomHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=BUILD_DIR, **kwargs)

    def end_headers(self):
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()

def main():
    if not os.path.isdir(BUILD_DIR):
        os.makedirs(BUILD_DIR, exist_ok=True)
        
    local_ip = get_local_ip()
    generate_index_html(local_ip)
    
    server_url = f"http://{local_ip}:{PORT}"
    troll_url = f"apple-magnifier://install?url={server_url}/{TIPA_NAME}"
    
    print("\n" + "=" * 60)
    print("  📱 TrollStore 局域网一键无线部署服务已就绪！")
    print("=" * 60)
    print(f"  👉 手机 Safari 打开此网址:  {server_url}")
    print(f"  ⚡️ 协议直达安装链接:       {troll_url}")
    print("=" * 60)
    print("  提示: 在手机 Safari 中点击「唤起 TrollStore 直接安装」即可秒级覆盖安装！")
    print("  按 Ctrl+C 可停止服务。\n")
    
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("0.0.0.0", PORT), CustomHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n服务已停止。")

if __name__ == "__main__":
    main()
