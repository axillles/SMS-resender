#!/usr/bin/env python3
"""
Локальный мок для aft_forward.php. Запускай на Mac, затем в Xcode:
Edit Scheme → Run → Arguments → Environment Variables: USE_MOCK_BACKEND = 1
Запускай приложение в симуляторе — запросы пойдут на 127.0.0.1:8080.
"""
import json
from http.server import HTTPServer, BaseHTTPRequestHandler

PORT = 8080

class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length) if length else b""
        try:
            data = json.loads(body.decode("utf-8"))
            print("\n[MOCK] POST", self.path)
            print("[MOCK] Body:", json.dumps(data, ensure_ascii=False, indent=2))
        except Exception as e:
            print("[MOCK] Raw body:", body[:500])
            print("[MOCK] Error:", e)
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        # Ответ в формате, который ждёт приложение
        if "/aft_register" in self.path:
            payload = {"status": "success", "registration_id": "mock-reg-id"}
        else:
            payload = {"status": "success", "details": {"sent": 1, "failed": 0}}
        self.wfile.write(json.dumps(payload).encode())

    def log_message(self, *args):
        pass  # не засорять вывод

if __name__ == "__main__":
    print(f"Mock forward server: http://127.0.0.1:{PORT}/api/aft_forward.php")
    print("Set USE_MOCK_BACKEND=1 in Xcode scheme and run the app.")
    HTTPServer(("", PORT), Handler).serve_forever()
