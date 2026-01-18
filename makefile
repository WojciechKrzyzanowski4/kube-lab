TAG						?= latest
API_DIR					?= api
IMAGE_NAME				?= kube-lab
CHART_DIR				?= devops/kube-lab
VALUES_FILE				?= $(CHART_DIR)/values.yaml
EXTRA_VALUES			?=
RELEASE_NAME			?= lab
NAMESPACE				?= kube-lab
KUBE_CONTEXT			?= docker-desktop
DOCS_DIR				?= docs
LAB_GUIDE				?= $(DOCS_DIR)/lab-tasks.md
BASE_URL				?= https://kube-lab-api.127.0.0.1.nip.io
ENV_FILE				?= devops/.env
SECRET_NAME				?= api-secret
TLS_SECRET_NAME     	?= tls-secret
TLS_CERT_FILE       	?= certs/tls.crt
TLS_KEY_FILE			?= certs/tls.key
INGRESS_MANIFEST_URL 	?= https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

MAKEFLAGS += --no-builtin-rules
.SUFFIXES:

ifeq ($(OS),Windows_NT)
BASH := "C:/Program Files/Git/bin/bash.exe"
else
BASH := bash
endif

.PHONY: help full context uninstall build deploy lab lab-steps grade


full: uninstall context setup secret tls-secret build deploy
	@echo
	@echo "Deployment triggered successfully!"
	@echo
	@echo "Next steps:"
	@echo "  - Check:   kubectl get pods,svc,ingress -n $(NAMESPACE) -l app.kubernetes.io/instance=$(RELEASE_NAME)"
	@echo "  - Logs:    kubectl logs deploy/$(NAMESPACE)-$(RELEASE_NAME) -n $(NAMESPACE) --tail=100 -f"
	@echo "Application access:"
	@echo "  - URL: $(BASE_URL)"
	@echo "  - Browser warnings about an insecure connection are expected."
	@echo "    This is normal in local environments (self-signed certificates)."

help:
	@echo "Kube Lab helpers:"
	@echo "  make help                          Show this help message"
	@echo "  make full TAG=dev                  Uninstall + switch context + build + deploy"
	@echo "  make deploy RELEASE_NAME=lab       Upgrade/install the Helm chart"
	@echo "  make grade BASE_URL=...            Run the 20-task grader (defaults to $(BASE_URL) via Ingress)"
	@echo


context:
	@CUR=$$(kubectl config current-context); \
	if [ "$$CUR" != "$(KUBE_CONTEXT)" ]; then \
	  echo "Switching kubectl context to $(KUBE_CONTEXT)..."; \
	  kubectl config use-context "$(KUBE_CONTEXT)"; \
	else \
	  echo "kubectl context already $(KUBE_CONTEXT)"; \
	fi

setup:
	@echo "Setting up Kubernetes prerequisites..."

	@echo "➡ Creating namespace '$(NAMESPACE)' (if not exists)..."
	@kubectl create namespace $(NAMESPACE) \
	  --dry-run=client -o yaml | kubectl apply -f -

	@echo "➡ Installing NGINX Ingress Controller..."
	@kubectl apply -f $(INGRESS_MANIFEST_URL)

	@echo "➡ Waiting for Ingress Controller to be ready..."
	@kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller

	@echo "Kubernetes setup completed"

secret:
	@if [ ! -f "$(ENV_FILE)" ]; then \
	  echo "Missing $(ENV_FILE). Create it first in the devops folder."; \
	  exit 1; \
	fi
	@echo "Creating/updating Kubernetes Secret '$(SECRET_NAME)' from $(ENV_FILE)..."
	@set -a; \
	  . $(ENV_FILE); \
	  set +a; \
	  kubectl create secret generic $(SECRET_NAME) \
	    --from-literal=API_KEY="$$API_KEY" \
	    --namespace $(NAMESPACE) \
	    --dry-run=client -o yaml | kubectl apply -f -
	@echo "Secret $(SECRET_NAME) applied to namespace $(NAMESPACE)"

tls-secret:
	@if [ ! -f "$(TLS_CERT_FILE)" ] || [ ! -f "$(TLS_KEY_FILE)" ]; then \
	  echo "Missing TLS cert or key."; \
	  echo "   Expected:"; \
	  echo "     $(TLS_CERT_FILE)"; \
	  echo "     $(TLS_KEY_FILE)"; \
	  echo "   Generate them first (e.g. using mkcert)."; \
	  exit 1; \
	fi
	@echo "Creating/updating Kubernetes TLS Secret '$(TLS_SECRET_NAME)'..."
	@kubectl create secret tls $(TLS_SECRET_NAME) \
	  --cert="$(TLS_CERT_FILE)" \
	  --key="$(TLS_KEY_FILE)" \
	  --namespace "$(NAMESPACE)" \
	  --dry-run=client -o yaml | kubectl apply -f -
	@echo "TLS Secret $(TLS_SECRET_NAME) applied to namespace $(NAMESPACE)"

uninstall:
	@echo "Uninstalling Helm release (if present): $(RELEASE_NAME) in $(NAMESPACE)"
	@helm uninstall "$(RELEASE_NAME)" -n "$(NAMESPACE)" >/dev/null 2>&1 || true
	@echo "Cleaning aux resources (if present)..."
	@kubectl delete configmap "$(RELEASE_NAME)" -n "$(NAMESPACE)" --ignore-not-found || true
	@sleep 2

build:
	@echo
	@echo "Building Docker image: $(IMAGE_NAME)"
	docker build -t "$(IMAGE_NAME)" "$(API_DIR)"

deploy:
	@echo
	@echo "Deploying Helm release: $(RELEASE_NAME) -> $(NAMESPACE)"
	helm upgrade --install "$(RELEASE_NAME)" "$(CHART_DIR)" \
	  -f "$(VALUES_FILE)" \
	  $(foreach vf,$(EXTRA_VALUES),-f $(vf)) \
	  --set api.image.repository=$(IMAGE_NAME) \
	  --set api.image.tag=$(TAG) \
	  --namespace "$(NAMESPACE)" \
	  --create-namespace \
	  --wait=false

grade:
	@echo "Running grader against BASE_URL=$(BASE_URL)..."
	@$(BASH) ./tasks.sh

