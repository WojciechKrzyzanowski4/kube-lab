worker_class = "gevent"
workers = 2
worker_connections = 100
bind = "0.0.0.0:5000"
timeout = 90
graceful_timeout = 30
keepalive = 30
backlog = 256
max_requests = 200
max_requests_jitter = 40
accesslog = "-"
errorlog = "-"
loglevel = "debug"
capture_output = True
preload_app = False


