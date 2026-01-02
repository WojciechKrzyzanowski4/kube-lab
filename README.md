# Kube Lab: End-to-End Kubernetes Delivery (Local)

Hands-on laboratory for shipping the sample Flask API with Docker, Helm, autoscaling, secrets, and a local-only workflow. No cloud accounts or GitHub Actions required.

## Prerequisites
- Docker, kubectl, Helm 3
- Access to a local Kubernetes cluster (Docker Desktop or kind).
- Metrics Server installed (required for HPA):  
  - Generic install: `kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml`  
  - If using kind with self-signed certs, patch args: <https://github.com/kubernetes-sigs/metrics-server#installation>
- Optional: kubeseal (for Sealed Secrets) <https://github.com/bitnami-labs/sealed-secrets>

## Repo Tour
- `api/` Flask app + Dockerfile
- `devops/kube-lab/` Helm chart (`values.yaml` controls image, secrets, autoscaling, ingress)
- `makefile` helper targets (local build and Helm deploy)
- `docs/` lab instructions (this file)
- `tests/tasks.sh` grading script for the 20 tasks (expects the app reachable at `BASE_URL`, default `http://kube-lab-api.127.0.0.1.nip.io`)

## Lab Objectives
1) Containerize and run the API locally.
2) Deploy to Kubernetes with Helm; iterate on values.
3) Manage configuration and secrets safely.
4) Enable autoscaling with HPA.
5) Understand deployment orchestration (rolling updates, health checks).
6) Complete 20 local tasks and self-grade with `tests/tasks.sh`.

## 1. Local Container Build
1. Inspect the app: `api/app.py`.
2. Build: `make build IMAGE_NAME=kube-lab`.
3. Run locally: `docker run --rm -p 5000:5000 kube-lab`.
4. Verify: `visit http://localhost:5000 in your browser` (local container smoke test).
5. You should get the message `Hello from Flask running locally!`
- Docker best practices: <https://docs.docker.com/develop/>

## 2. Helm-Based Deploy to Local Cluster
1. Switch context if needed: `make context KUBE_CONTEXT=docker-desktop` (or your context).
2. Install/upgrade: `make deploy RELEASE_NAME=lab NAMESPACE=kube-lab IMAGE_NAME=kube-lab`.
3. Check resources:
   - `kubectl get pods -n kube-lab`
   - `kubectl describe deploy kube-lab-lab -n kube-lab`
4. Port-forward for testing: `kubectl port-forward svc/kube-lab-lab 5000:80 -n kube-lab`.
5. Verify: `visit http://localhost:5000 in your browser` (local container smoke test). 
6. You should get the message `Hello from Flask running in Kubernetes via Ingress!`
- Helm chart guide: <https://helm.sh/docs/chart_template_guide/>

## 3. Configuration and Secret Management
### ConfigMaps
- Values live in `config:` inside `values.yaml`; rendered by `templates/configmap.yaml`.
- Exercise: add a new env var, redeploy with `make deploy EXTRA_VALUES=./devops/kube-lab/values.yaml`.
- Docs: <https://kubernetes.io/docs/concepts/configuration/configmap/>

### Secrets
- Plain secrets live under `secret:` in `values.yaml`; rendered by `templates/secret.yaml`.
- Safer workflow with Sealed Secrets:
  1. Install controller: <https://github.com/bitnami-labs/sealed-secrets#installation>
  2. Create secret locally: `kubectl create secret generic api-token --from-literal=API_TOKEN=change-me --namespace kube-lab --dry-run=client -o yaml > tmp-secret.yaml`
  3. Seal: `kubeseal --format yaml < tmp-secret.yaml > devops/kube-lab/templates/sealedsecret.yaml`
  4. Adjust values to mount/use the sealed secret.
- Secret patterns: <https://kubernetes.io/docs/concepts/security/secrets/>

## 4. Health, Probes, and Rolling Updates
- Liveness/readiness are defined in `values.yaml` (`api.livenessProbe`, `api.readinessProbe`) and used in `templates/deployment.yaml`.
- Rolling updates are handled by the Deployment strategy (see `deployment.yaml`).
- Exercises:
  1. Break the liveness path to observe restarts.
  2. Change `maxUnavailable`/`maxSurge` in the Deployment to see rollout behavior.
- Deployments guide: <https://kubernetes.io/docs/concepts/workloads/controllers/deployment/>

## 5. Autoscaling with HPA
1. Ensure Metrics Server is installed.
2. Enable HPA in `values.yaml`:
   ```yaml
   autoscaling:
     enabled: true
     minReplicas: 2
     maxReplicas: 5
     targetCPUUtilizationPercentage: 60
   ```
3. Redeploy: `make deploy`.
4. Generate load (e.g., `hey` or `ab`) and watch scaling: `kubectl get hpa -n kube-lab -w`.
- HPA docs: <https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/>

## 6. Ingress and Traffic
- Ingress host defaults to `kube-lab-api.127.0.0.1.nip.io` (`values.yaml -> api.ingress`).
- If using kind, install ingress-nginx: <https://kind.sigs.k8s.io/docs/user/ingress/>
- Exercise: add TLS config, or change host/path and test routing.
- Ingress basics: <https://kubernetes.io/docs/concepts/services-networking/ingress/>

## 7. Observability Quick Wins
- Logs: `kubectl logs deploy/kube-lab-lab -n kube-lab -f`.
- Events: `kubectl get events -n kube-lab --sort-by=.lastTimestamp`.
- Add Prometheus annotations on the Service if scraping is available.
- Observability patterns: <https://sre.google/sre-book/monitoring-distributed-systems/>

## 8. The 20 Local Tasks (all gradable)
Work locally; no cloud dependencies. Keep the app reachable via Ingress at `BASE_URL` (default `http://kube-lab-api.127.0.0.1.nip.io`).  
Prereq: install an Ingress controller (e.g., ingress-nginx) on your cluster: <https://kubernetes.github.io/ingress-nginx/deploy/>

**API tasks**
1) Add `/healthz` that returns JSON `{"status":"ok"}` (HTTP 200).  
2) Extend `/config` to also return `app_env` (from `APP_ENV`, default `dev`).  
3) Add `/version` returning `{"version": <APP_VERSION or "v0">}` this should be based on the Chart version and propagated through the config Map (se.  
4) Add `/secret-check` returning `{"has_dummy_token": true|false}` depending on env `DUMMY_TOKEN` presence.  

**Helm/values tasks**
1) Set `api.replicas` to `3` in `devops/kube-lab/values.yaml`.  
2) Add `GREETING_PREFIX` to the `config` map (e.g., `"HelloLab"`).  
3) Add `API_TOKEN` to the `secret` map.  
4) Enable HPA: `autoscaling.enabled: true`.  
5) Set `autoscaling.minReplicas: 2`.  
6) Set `autoscaling.maxReplicas: 5`.  
7) Set `autoscaling.targetCPUUtilizationPercentage: 60`.  
8) Add an extra ingress host `kube-lab.local` to `api.ingress.hosts`.  
9) Create `devops/kube-lab/values.dev.yaml` with `api.replicas: 1` (override for a lean dev setup).

## 9. Grading the Tasks
- Ensure the app is running and reachable at `BASE_URL` (defaults to `http://kube-lab-api.127.0.0.1.nip.io`).
  - Deploy via Helm so the Ingress is created: `make deploy RELEASE_NAME=lab NAMESPACE=kube-lab IMAGE_NAME=kube-lab TAG=latest`.
  - Verify ingress: `kubectl get ingress -n kube-lab` then `curl http://kube-lab-api.127.0.0.1.nip.io/healthz`.
- Run the grader: `./tests/tasks.sh` (or `BASE_URL=http://kube-lab.local ./tests/tasks.sh`).
- Or via make: `make grade BASE_URL=http://kube-lab-api.127.0.0.1.nip.io`.
- Output shows pass/fail per task plus a total score out of 20.

## Cleanup
- Helm uninstall: `make uninstall RELEASE_NAME=lab NAMESPACE=kube-lab`.
- Delete cluster if using kind: `kind delete cluster --name kube-lab`.

## Completion Checklist
- [ ] Container builds and runs locally
- [ ] Helm release installed; ingress reachable
- [ ] Secrets managed securely (Sealed Secrets or external secret store)
- [ ] HPA scales under load
- [ ] Rolling updates verified
- [ ] All 14 local tasks graded green by `tests/tasks.sh`
