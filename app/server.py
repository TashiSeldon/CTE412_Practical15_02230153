import json
import os
import socket
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

# Application configuration (set at build time or by the Deployment).
APP_VERSION = os.environ.get("APP_VERSION", "1.0.0")
STUDENT_ID = os.environ.get("STUDENT_ID", "02230153")
FEATURE_PINNED = os.environ.get("FEATURE_PINNED", "false").lower() == "true"
BROKEN_HEALTH = os.environ.get("BROKEN_HEALTH", "false").lower() == "true"

# Record startup time to simulate a five-second warm-up.
START_TIME = time.monotonic()

# Baseline notices shared by all three releases.
BASE_NOTICES = [
    {"id": 1, "title": "Library Hours", "body": "The library opens at 8 AM."},
    {"id": 2, "title": "Campus Meeting", "body": "The campus meeting is on Friday."},
    {"id": 3, "title": "Exam Schedule", "body": "Check the examination timetable."},
]


class NoticeBoardHandler(BaseHTTPRequestHandler):

    # Return a JSON response with the appropriate HTTP status.
    def send_json(self, status, data):
        body = json.dumps(data).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        # Endpoint 1: version, student identity and serving pod (container hostname).
        if self.path == "/version":
            self.send_json(200, {
                "version": APP_VERSION,
                "student": STUDENT_ID,
                "pod": socket.gethostname(),
            })

        # Endpoint 2: health.
        elif self.path == "/healthz":
            # Broken release never reports healthy.
            if BROKEN_HEALTH or time.monotonic() - START_TIME < 5:
                self.send_json(503, {"status": "unhealthy"})
            else:
                self.send_json(200, {"status": "healthy"})

        # Endpoint 3: notices.
        elif self.path == "/notices":
            notices = [dict(n) for n in BASE_NOTICES]
            if APP_VERSION != "1.0.0":
                categories = ["Facilities", "Events", "Examinations"]
                pinned_values = [True, False, True]
                for n, c, p in zip(notices, categories, pinned_values):
                    n["category"] = c
                    n["pinned"] = p
                if FEATURE_PINNED:
                    # Stable sort: pinned notices first.
                    notices.sort(key=lambda n: not n["pinned"])
            response = {"notices": notices}
            if APP_VERSION != "1.0.0":
                response["pinnedFirst"] = FEATURE_PINNED
            self.send_json(200, response)

        else:
            self.send_json(404, {"error": "Not found"})

    # Print HTTP request logs to stdout.
    def log_message(self, format_string, *args):
        print("%s - %s" % (self.address_string(), format_string % args), flush=True)


if __name__ == "__main__":
    server = ThreadingHTTPServer(("0.0.0.0", 8080), NoticeBoardHandler)
    print("Notice Board version %s starting on port 8080" % APP_VERSION, flush=True)
    server.serve_forever()