.PHONY: help deploy install-mta-cli analyze-openjdk11 analyze-openjdk17 analyze-openjdk21 analyze-cloud analyze-bc4j analyze-all
help:
	@echo "Validated pattern demo-mta-java (hub-only CPU)"
	@echo "  make deploy              Install MTA, Serverless, the CPU model, and Dev Spaces"
	@echo "  make analyze-openjdk11   MTA CLI report → mta-output/openjdk11"
	@echo "  make analyze-openjdk17   MTA CLI report → mta-output/openjdk17"
	@echo "  make analyze-openjdk21   MTA CLI report → mta-output/openjdk21"
	@echo "  make analyze-cloud       MTA CLI report → mta-output/cloud-readiness"
	@echo "  make analyze-bc4j        MTA CLI report → mta-output/bc4j"
	@echo "  make analyze-all         All five CLI reports"
	@echo "  Pattern CR               oc apply -f examples/pattern-cr/hub-only-cpu.yaml"
	@echo "  RHDP path                examples/bootstrap (Field Content GitOps path)"

deploy:
	helm upgrade --install mta-demo ./charts/mta-demo -n mta-demo --create-namespace \
		--set mta.subscription.enabled=true
	helm upgrade --install openshift-serverless ./charts/openshift-serverless -n knative-serving --create-namespace \
		--set subscription.enabled=true
	helm upgrade --install devspaces ./charts/devspaces -n openshift-devspaces --create-namespace \
		--set subscription.enabled=true
	helm upgrade --install cpu-inference ./charts/cpu-inference -n mta-demo

analyze-openjdk11 analyze-openjdk17 analyze-openjdk21 analyze-cloud analyze-bc4j analyze-all: install-mta-cli

install-mta-cli:
	bash scripts/install-mta-cli.sh

analyze-openjdk11:
	bash scripts/mta-cli-analyze.sh openjdk11

analyze-openjdk17:
	bash scripts/mta-cli-analyze.sh openjdk17

analyze-openjdk21:
	bash scripts/mta-cli-analyze.sh openjdk21

analyze-cloud:
	bash scripts/mta-cli-analyze.sh cloud-readiness

analyze-bc4j:
	bash scripts/mta-cli-analyze.sh bc4j

analyze-all:
	bash scripts/mta-cli-analyze.sh all
