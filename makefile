TAG        			?= latest
API_DIR 			?= api
IMAGE_NAME    		?= kube-lab
CHART_DIR     		?= devops/kube-lab
VALUES_FILE   		?= $(CHART_DIR)/values.yaml
EXTRA_VALUES  		?=
RELEASE_NAME  		?= release-1
NAMESPACE     		?= kube-lab
KUBE_CONTEXT  		?= docker-desktop
DOCS_DIR    		?= docs
LAB_GUIDE   		?= $(DOCS_DIR)/lab-guide.md
BASE_URL			?= http://kube-lab-api.127.0.0.1.nip.io

.PHONY: help full context uninstall build deploy lab lab-steps grade


full: uninstall context build deploy
	@echo
	@echo "Deployment triggered successfully!"
	@echo
	@echo "Next steps:"
	@echo "  - Check:   kubectl get pods,svc,ingress -n $(NAMESPACE) -l app.kubernetes.io/instance=$(RELEASE_NAME)"
	@echo "  - Logs:    kubectl logs deploy/$(NAMESPACE)-$(RELEASE_NAME) -n $(NAMESPACE) --tail=100 -f"
	@echo "  - Forward: kubectl port-forward svc/$(NAMESPACE)-$(RELEASE_NAME) 5000:80 -n $(NAMESPACE)"
	@echo "  - Guide:   $(LAB_GUIDE)"


help:
	@echo "Kube Lab helpers:"
	@echo "  make help                          Show this help message"
	@echo "  make full TAG=dev                  Uninstall + switch context + build + deploy"
	@echo "  make deploy RELEASE_NAME=lab       Upgrade/install the Helm chart"
	@echo "  make lab                           Print the short lab outline with links"
	@echo "  make lab-steps                     Show detailed, step-by-step checklist"
	@echo "  make grade BASE_URL=...            Run the 20-task grader (defaults to $(BASE_URL) via Ingress)"
	@echo
	@echo "Docs:"
	@echo "  $(LAB_GUIDE)"


context:
	@CUR=$$(kubectl config current-context); \
	if [ "$$CUR" != "$(KUBE_CONTEXT)" ]; then \
	  echo "Switching kubectl context to $(KUBE_CONTEXT)..."; \
	  kubectl config use-context "$(KUBE_CONTEXT)"; \
	else \
	  echo "kubectl context already $(KUBE_CONTEXT)"; \
	fi


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


lab:
	@echo "Kube Lab outline (read $(LAB_GUIDE) for full details):"
	@echo "1) Build and test API locally: docker build -t $(IMAGE_NAME):$(TAG) $(API_DIR)"
	@echo "2) Switch context & deploy with Helm: make context && make deploy RELEASE_NAME=lab NAMESPACE=$(NAMESPACE)"
	@echo "3) Configure secrets safely (Secrets/Sealed Secrets): https://kubernetes.io/docs/concepts/security/secrets/"
	@echo "4) Tune probes/rollouts in values.yaml (health + rolling updates): https://kubernetes.io/docs/concepts/workloads/controllers/deployment/"
	@echo "5) Enable autoscaling: set autoscaling.enabled=true in values.yaml and redeploy."
	@echo "6) Ingress & traffic: adjust api.ingress.* in values.yaml."
	@echo "7) Complete the 20 local tasks (see $(LAB_GUIDE))."
	@echo "8) Grade via Ingress: make grade BASE_URL=$(BASE_URL)"
	@echo "9) Cleanup: make uninstall RELEASE_NAME=lab NAMESPACE=$(NAMESPACE)."


lab-steps:
	@echo "Detailed checklist:"
	@echo " - Inspect code: api/app.py; understand readiness/liveness probes."
	@echo " - Build image: make build IMAGE_NAME=$(IMAGE_NAME) TAG=$(TAG)"
	@echo " - Run locally: docker run --rm -p 5000:5000 $(IMAGE_NAME):$(TAG) && curl http://127.0.0.1:5000/healthz (for quick smoke), then deploy for ingress."
	@echo " - Deploy: make deploy RELEASE_NAME=lab NAMESPACE=$(NAMESPACE) IMAGE_NAME=$(IMAGE_NAME) TAG=$(TAG)"
	@echo " - Secrets: edit values.yaml secret block or add SealedSecret template."
	@echo " - Config: adjust config.* keys for env vars; redeploy."
	@echo " - Autoscaling: enable autoscaling.* and watch 'kubectl get hpa -w' under load."
	@echo " - Orchestration: tweak maxSurge/maxUnavailable in templates/deployment.yaml to observe rollouts."
	@echo " - Finish the 14 local tasks in $(LAB_GUIDE), then run: make grade BASE_URL=$(BASE_URL)"
	@echo "See $(LAB_GUIDE) for task descriptions and tips."


grade:
	@echo "Running grader against BASE_URL=$(BASE_URL)..."
	@BASE_URL=$(BASE_URL) ./tasks.sh
