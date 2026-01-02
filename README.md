# Kube Lab: End-to-End Kubernetes Delivery (Local)

Hands-on laboratory for shipping the sample Flask API with Docker, Helm, autoscaling, secrets, and a local-only workflow.

## Prerequisites
- Docker, kubectl, Helm 3 and make
- Access to a local Kubernetes cluster (Docker Desktop or kind).


## Repo Tour
- `api/` Flask app + Dockerfile
- `devops/kube-lab/` Helm chart (`values.yaml` controls image, secrets, autoscaling, ingress)
- `makefile` helper targets (local build and Helm deploy)
- `tasks.sh` grading script for the 20 tasks (expects the app reachable at `BASE_URL`, default `http://kube-lab-api.127.0.0.1.nip.io`)

## Lab Objectives
1) Containerize and run the API locally.
2) Deploy to Kubernetes with Helm; iterate on values.
3) Manage configuration and secrets safely.
4) Enable autoscaling with HPA.
5) Understand deployment orchestration (rolling updates, health checks).
6) Complete exercises and self-grade with `tests/tasks.sh`.


This laboratory guides you through building, running, and orchestrating a simple Flask application using Docker, Helm, and Kubernetes.

The same container image is used in all steps.
Only runtime configuration changes.

## 1. Local Container Build (Docker Only)

In this step, you verify that the application works without Kubernetes.

Docker best practices: https://docs.docker.com/develop/

### What is happening

- You build a Docker image from the Flask application
- You run it locally
- You verify the default behavior when no Kubernetes configuration is present

### Steps

1. Inspect the application code:

   Open `api/app.py` and locate the index route:

   ```python
   @flask_app.route("/")
   def index():
       greeting = os.getenv(
           "APP_GREETING",
           "Hello from Flask running locally!"
       )
       return greeting, 200
   ```
   
   Observe:
   - The application reads the `APP_GREETING` environment variable
   - A default value is used when the variable is not set
   

2. Build the container image:
   ```bash
   make build IMAGE_NAME=kube-lab
   ```
   This:
   - Runs `docker build`
   - Produces a local image named `kube-lab`


3. Run the container locally:
   ```bash
   docker run --rm -p 5000:5000 kube-lab
   ```
4. Verify the application:
   Open your browser and visit:
   ```
   http://localhost:5000
   ```
   Expected output in the Greeting section of the application:
   ```
   Hello from Flask running locally!
   ```

### Learning outcome

- Containers run independently of Kubernetes
- Environment variables control runtime behavior
- Defaults matter when configuration is missing


## 2. Helm-Based Deployment to Local Kubernetes Cluster

In this step, you deploy the same container image into Kubernetes using Helm.

Helm chart guide: https://helm.sh/docs/chart_template_guide/

### What is happening

- Helm renders Kubernetes manifests
- Kubernetes injects configuration via ConfigMaps and Secrets
- The application behavior changes without rebuilding the image

### Steps

1. Ensure you are using the correct Kubernetes context:

   ```bash
   make context KUBE_CONTEXT=docker-desktop
   ```

   If your current context is already `docker-desktop`, this step does nothing.


2. Deploy the full stack:
   ```bash
   make full
   ```
   This command performs the following actions in order:

    ```bash
    make uninstall  # removes any previous Helm release
    ```
   ```bash
   make context     # ensures the correct Kubernetes cluster is selected
   ```
   ```bash
   make build       # builds the Docker image locally
   ```
   ```bash
   make deploy      # installs/upgrades the Helm chart
   ```
   
3. Inspect the created resources:

   ```bash
   kubectl get pods -n kube-lab
   kubectl describe deployment kube-lab-lab -n kube-lab
   ```

4. Verify the application via Ingress:

   Open your browser and visit:
   ```
   http://kube-lab-api.127.0.0.1.nip.io
   ```
   Expected output in the Greeting section of the application:
   ```
   Hello from Flask running in Kubernetes via Ingress!
   ```

### Learning outcome

- Helm deploys applications declaratively
- Kubernetes injects configuration at runtime
- The same image behaves differently depending on environment


## 3. Configuration and Secret Management

This section focuses on observing how configuration flows from Helm to Kubernetes to the application.

No values should be modified yet.

ConfigMaps: https://kubernetes.io/docs/concepts/configuration/configmap/

Secrets: https://kubernetes.io/docs/concepts/security/secrets/


### ConfigMaps (Application Configuration)

#### What is happening

- Helm renders a ConfigMap from `values.yaml`
- Kubernetes injects ConfigMap values as environment variables
- The application reads them at runtime


#### Steps

1. Inspect the application code:

   ```python
   @flask_app.route("/")
   def index():
       return render_template(
           "index.html",
           greeting=os.getenv(
               "APP_GREETING",
               "Hello from Flask running locally!"
           ),
           app_name=os.getenv("APP_NAME"),
           has_secret=os.getenv("API_KEY") is not None
       ), 200
   ```

   Observe:
   - `APP_GREETING` controls the greeting text
   - A default value exists when the variable is missing


2. Inspect Helm values:

   Open `devops/kube-lab/values.yaml` and locate:

   ```yaml
   config:
     APP_GREETING: "Hello from Flask running in Kubernetes via Ingress!"
   ```


3. Inspect the rendered ConfigMap:

   ```bash
   kubectl get configmap kube-lab-lab -n kube-lab -o yaml
   ```


4. Verify runtime behavior:

   Refresh the application page in your browser and observe the greeting.


#### Learning outcome

- ConfigMaps externalize configuration
- Helm templates configuration, Kubernetes injects it
- Applications remain environment-agnostic


### Secrets (Sensitive Configuration)

Secrets follow a similar flow to ConfigMaps, but with stricter handling.

#### What is happening

- Secrets are not stored in `values.yaml`
- Secrets originate from a local `.env` file
- Kubernetes Secrets are created imperatively
- Helm only references the Secret by name

#### Steps

1. Inspect the application logic:

   ```python
   has_secret = os.getenv("API_KEY") is not None
   ```

   Observe:
   - The application only checks for presence
   - The secret value is never exposed


2. Inspect Helm values:

   Open `devops/kube-lab/values.yaml` and locate:
   ```yaml
   api:
     secret:
       name: api-secret
   ```
   Observe:
   - Helm knows which secret to use
   - Helm does not know the secret value


3. Inspect how the Deployment references the Secret:

   Open `devops/kube-lab/templates/deployment.yaml` and locate:
   ```yaml
   envFrom:
     - configMapRef:
         name: kube-lab-lab
     - secretRef:
         name: api-secret
   ```
   
4. Inspect the Kubernetes Secret:

   ```bash
   kubectl get secret api-secret -n kube-lab
   kubectl get secret api-secret -n kube-lab -o yaml
   ```
   
5. Verify runtime behavior:

   Visit the application dashboard and observe the Secrets section.


#### Learning outcome

- Secrets must not be committed
- Kubernetes is the runtime trust boundary
- Helm references secrets but does not manage their values
- Configuration and secrets follow similar but distinct paths


## Makefile: What It Actually Does

The Makefile is the orchestration layer of this lab.

It ensures:
- repeatability
- correct ordering
- minimal manual commands


### Key targets

| Target | Purpose |
|------|---------|
| make build | Builds the Docker image |
| make secrets | Creates/updates Kubernetes Secrets from `.env` |
| make deploy | Installs/upgrades the Helm chart |
| make full | Runs the full workflow |
| make uninstall | Removes the Helm release |
| make context | Ensures correct Kubernetes context |
| make grade | Runs the automated grader |

---

### Why not run the same commands manually?

This mirrors real-world DevOps workflows:

- Imperative steps for secrets
- Declarative deployment via Helm
- Idempotent commands
- Clear separation of concerns


## 5. Autoscaling with HPA (Horizontal Pod Autoscaler)

In this step, you will enable autoscaling for the API Deployment using an HPA.
An HPA needs CPU/Memory metrics to work — these metrics are provided by the **Metrics Server**.

Goal:
- Enable HPA in the Helm values
- Generate load
- Observe the Deployment scaling up/down

---

### 0) Prerequisites: Metrics Server (Required)

HPA will not work until Metrics Server is installed.

1) Check whether Metrics Server is already running:

```bash
kubectl get pods -n kube-system | grep metrics-server || true
```

2) If it is NOT installed, install it (generic installation):

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

3) Verify it becomes Ready:

```bash
kubectl rollout status deployment/metrics-server -n kube-system
```

4) Verify metrics are available:

```bash
kubectl top nodes
kubectl top pods -n kube-lab
```

If `kubectl top ...` fails, Metrics Server is not working correctly yet.

Notes:
- If you are using **kind** with self-signed certs, you may need to patch Metrics Server args.
- Reference: https://github.com/kubernetes-sigs/metrics-server#installation

---

### 1) Confirm your current Deployment replica count

Before enabling autoscaling, confirm how many replicas are running:

```bash
kubectl get deploy -n kube-lab
kubectl get pods -n kube-lab
```

You should see `api.replicas` worth of pods (from your Helm values).

---

### 2) Enable autoscaling in Helm values

Open:

```
devops/kube-lab/values.yaml
```

Locate and set the autoscaling section to:

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 5
  targetCPUUtilizationPercentage: 60
```

Important notes:
- `minReplicas` is the lowest value the HPA will allow
- `maxReplicas` is the upper safety cap
- `targetCPUUtilizationPercentage` controls when scaling triggers

---

### 3) Redeploy the chart

Apply the updated values:

```bash
make deploy
```

---

### 4) Observe the HPA object

Check that the HPA exists:

```bash
kubectl get hpa -n kube-lab
```

Then watch it continuously:

```bash
kubectl get hpa -n kube-lab -w
```

At first, it may show:
- unknown metrics (until Metrics Server reports them)
- low utilization (before load)

---

### 5) Generate load and watch scaling

You now need to generate CPU load so the HPA has a reason to scale.

Option A: Use `hey` (recommended)

1) Run a quick load test:

```bash
hey -z 60s -c 20 http://kube-lab-api.127.0.0.1.nip.io/
```

Option B: Use `ab` (ApacheBench)

```bash
ab -n 5000 -c 20 http://kube-lab-api.127.0.0.1.nip.io/
```

While load is running, watch:
- HPA scaling decisions:

```bash
kubectl get hpa -n kube-lab -w
```

- Pod count changes:

```bash
kubectl get pods -n kube-lab -w
```

---

### 6) Verify scaling behavior

You should observe:
- replicas increasing above `minReplicas` while load is present
- replicas decreasing back toward `minReplicas` after load stops (may take a few minutes)

To see more detail:

```bash
kubectl describe hpa -n kube-lab
```

---

### Learning Objective

After completing this exercise, you should understand:

- Why HPA requires Metrics Server
- How HPA uses CPU utilization to make scaling decisions
- How Helm values enable/disable HPA
- How scaling affects the number of running pods under load

---

### Documentation

HPA:
https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/

Metrics Server installation:
https://github.com/kubernetes-sigs/metrics-server#installation


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
