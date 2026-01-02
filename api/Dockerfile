FROM python:3.13-slim AS builder

WORKDIR /app

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .

RUN pip install --upgrade pip \
 && pip install  --no-cache-dir -r requirements.txt --timeout=100 --index-url=https://pypi.python.org/simple

FROM python:3.13-slim

WORKDIR /app

RUN apt-get update \
 && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN addgroup -gid 1000 appuser \
 && adduser --uid 1000 --gid 1000 --disabled-password -gecos "" appuser

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh && chmod 0755 /usr/local/bin/entrypoint.sh

COPY . .

RUN chown -R appuser:appuser /app

USER appuser

EXPOSE 5000

ENTRYPOINT ["entrypoint.sh"]

