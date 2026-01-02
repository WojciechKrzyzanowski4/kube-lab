#!/usr/bin/env bash
gunicorn -c gunicorn.conf.py app:flask_app