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
5. Stop the running container

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
