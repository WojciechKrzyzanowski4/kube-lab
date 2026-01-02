# Kube Lab: End-to-End Kubernetes Delivery (Local)

Hands-on laboratory for shipping the sample Flask API with Docker, Helm, secrets, and a local-only workflow.

## Prerequisites
- Docker, kubectl, Helm 3 and make
- Access to a local Kubernetes cluster (Docker Desktop or kind).

## Repo Tour
- `api/` Flask app + Dockerfile
- `devops/kube-lab/` Helm chart (`values.yaml` controls image, secrets, autoscaling, ingress)
- `makefile` helper targets (local build and Helm deploy)
- `tasks.sh` grading script for the 20 tasks (expects the app reachable at `BASE_URL`, default `http://kube-lab-api.127.0.0.1.nip.io`)
- `docs/lab-course.md` guide on the first part of the laboratory
- `docs/lab-tasks.md` step-by-step task list

## Lab Objectives
1) Containerize and run the API locally.
2) Deploy to Kubernetes with Helm; iterate on values.
3) Manage configuration and secrets safely.
4) Understand deployment orchestration.
5) Complete the 20 Helm-focused exercises and self-grade with `tasks.sh`.
