.PHONY: help deploy
help:
	@echo "Validated pattern demo-mta-java (hub-only CPU)"
	@echo "  make deploy   Install MTA, Serverless, the CPU model, and Dev Spaces on the current cluster"
	@echo "  Pattern CR    oc apply -f examples/pattern-cr/hub-only-cpu.yaml"
	@echo "  RHDP path     examples/bootstrap (Field Content GitOps path)"

deploy:
	helm upgrade --install mta-demo ./charts/mta-demo -n mta-demo --create-namespace \
		--set mta.subscription.enabled=true
	helm upgrade --install openshift-serverless ./charts/openshift-serverless -n knative-serving --create-namespace \
		--set subscription.enabled=true
	helm upgrade --install devspaces ./charts/devspaces -n openshift-devspaces --create-namespace \
		--set subscription.enabled=true
	helm upgrade --install cpu-inference ./charts/cpu-inference -n mta-demo
