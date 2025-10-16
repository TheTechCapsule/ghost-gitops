# ---------- Config ----------
OVERLAY ?= dev                 # dev | staging | prod
KNS ?= $(if $(findstring $(OVERLAY),staging),ghost-staging,default)

KUSTOMIZE ?= kustomize
KUBECTL   ?= kubectl
KUBECONFORM ?= kubeconform

APP_PATH := apps/ghost/overlays/$(OVERLAY)
PROD_PATH := apps/ghost/overlays/prod

# ---------- Help ----------
.PHONY: help
help:
	@echo "Targets:"
	@echo "  build-(dev|staging|prod)   Build overlay manifests"
	@echo "  apply-(dev|staging|prod)   Apply overlay to cluster"
	@echo "  delete-(dev|staging|prod)  Delete overlay from cluster"
	@echo "  validate                   Kubeconform validate all overlays"
	@echo "  guard-prod-latest          Fail if ':latest' appears in prod"
	@echo "  rollout                    Wait for MySQL & Ghost rollout in KNS=$(KNS)"
	@echo "  pf                         Port-forward Ghost svc to :8080 (KNS=$(KNS))"
	@echo "  logs                       Tail Ghost & MySQL logs (KNS=$(KNS))"
	@echo "  backup-db-now              Trigger DB backup Job now (KNS=$(KNS))"
	@echo "  backup-content-now         Trigger content backup Job now (KNS=$(KNS))"
	@echo "  verify-now                 Trigger verify Job now (KNS=$(KNS))"
	@echo "  prune-now                  Trigger prune Job now (KNS=$(KNS))"

# ---------- Build ----------
.PHONY: build-dev build-staging build-prod
build-dev:
	$(KUSTOMIZE) build apps/ghost/overlays/dev >/dev/null && echo "OK: dev"
build-staging:
	$(KUSTOMIZE) build apps/ghost/overlays/staging >/dev/null && echo "OK: staging"
build-prod:
	$(KUSTOMIZE) build $(PROD_PATH) >/dev/null && echo "OK: prod"

# ---------- Apply / Delete ----------
.PHONY: apply-dev apply-staging apply-prod
apply-dev:
	$(KUSTOMIZE) build apps/ghost/overlays/dev | $(KUBECTL) apply -f -
apply-staging:
	$(KUSTOMIZE) build apps/ghost/overlays/staging | $(KUBECTL) apply -f -
apply-prod:
	$(KUSTOMIZE) build $(PROD_PATH) | $(KUBECTL) apply -f -

.PHONY: delete-dev delete-staging delete-prod
delete-dev:
	$(KUSTOMIZE) build apps/ghost/overlays/dev | $(KUBECTL) delete -f - || true
delete-staging:
	$(KUSTOMIZE) build apps/ghost/overlays/staging | $(KUBECTL) delete -f - || true
delete-prod:
	$(KUSTOMIZE) build $(PROD_PATH) | $(KUBECTL) delete -f - || true

# ---------- Validate (CI-ish) ----------
.PHONY: validate guard-prod-latest
validate:
	@set -e; \
	for o in dev staging prod ci; do \
	  echo "== $$o =="; \
	  $(KUSTOMIZE) build apps/ghost/overlays/$$o | $(KUBECONFORM) -strict -ignore-missing-schemas -summary -; \
	done

guard-prod-latest:
	@tmp=$$(mktemp); \
	$(KUSTOMIZE) build $(PROD_PATH) > $$tmp; \
	if grep -E '^\s*image:\s+[^:]+:latest(\s|$$)' $$tmp; then \
	  echo 'Error: :latest tag found in prod overlay images' >&2; rm -f $$tmp; exit 1; \
	fi; \
	rm -f $$tmp; echo "OK: no ':latest' in prod"

# ---------- Ops QoL ----------
.PHONY: rollout pf logs
rollout:
	@echo "Namespace: $(KNS)  (OVERLAY=$(OVERLAY))"
	$(KUBECTL) -n $(KNS) rollout status statefulset/ghost-mysql --timeout=5m
	$(KUBECTL) -n $(KNS) rollout status deploy/ghost --timeout=5m

pf:
	@echo "Port-forwarding svc/ghost -> 8080 (KNS=$(KNS))"
	$(KUBECTL) -n $(KNS) port-forward svc/ghost 8080:2368

logs:
	@echo "---- ghost (last 200) ----"
	-$(KUBECTL) -n $(KNS) logs deploy/ghost --all-containers --tail=200
	@echo "---- ghost-mysql (last 200) ----"
	-$(KUBECTL) -n $(KNS) logs statefulset/ghost-mysql --all-containers --tail=200

# ---------- Backups (on-demand) ----------
.PHONY: backup-db-now backup-content-now verify-now prune-now
backup-db-now:
	$(KUBECTL) -n $(KNS) create job --from=cronjob/ghost-db-backup ghost-db-backup-now-$$RANDOM

backup-content-now:
	$(KUBECTL) -n $(KNS) create job --from=cronjob/ghost-content-backup ghost-content-backup-now-$$RANDOM

verify-now:
	$(KUBECTL) -n $(KNS) create job --from=cronjob/ghost-backup-verify ghost-backup-verify-now-$$RANDOM

prune-now:
	$(KUBECTL) -n $(KNS) create job --from=cronjob/ghost-backup-prune ghost-backup-prune-now-$$RANDOM
