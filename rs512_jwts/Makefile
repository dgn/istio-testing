NS := default

all: delete-cluster create-cluster reinstall-istio create test

include ../common.mk

create:
	@${KUBECTL_WITH_CFG} label ns ${NS} istio-injection=enabled || echo .
	@${KUBECTL_WITH_CFG} apply -f httpbin.yaml -n ${NS}
	@${KUBECTL_WITH_CFG} apply -f sleep.yaml -n ${NS}
	@${KUBECTL_WITH_CFG} rollout status deployment/httpbin -n ${NS}
	@${KUBECTL_WITH_CFG} rollout status deployment/sleep -n ${NS}

delete:
	@${KUBECTL_WITH_CFG} delete -f httpbin.yaml -n ${NS}
	@${KUBECTL_WITH_CFG} delete -f sleep.yaml -n ${NS}

test:
	@printf "Requesting without JWT: Expected 401, got "
	@${KUBECTL_WITH_CFG} exec $(shell ${KUBECTL_WITH_CFG} get pods -n ${NS} --field-selector "status.phase=Running" -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c sleep -- \
		curl -s -o /dev/null -w "%{http_code}\n" httpbin:80/headers
	@printf "Requesting with JWT:    Expected 200, got "
	@${KUBECTL_WITH_CFG} exec $(shell ${KUBECTL_WITH_CFG} get pods -n ${NS} --field-selector "status.phase=Running" -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c sleep -- \
		curl -s -o /dev/null -w "%{http_code}\n" httpbin:80/headers \
		--header 'Authorization: Bearer $(shell cat token.jwt)'

reinstall-istio:
	@${KUBECTL_WITH_CFG} create namespace istio-system || echo Namespace already exists
	@cd ${ISTIO}/istio && helm template install/kubernetes/helm/istio-init --name istio-init --namespace istio-system \
		| ${KUBECTL_WITH_CFG} apply -f -
	@sleep 60
	@cd ${ISTIO}/istio && helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
		| ${KUBECTL_WITH_CFG} apply -f -
	@${KUBECTL_WITH_CFG} rollout status deployment/istio-pilot --timeout=2m -n istio-system
	@${KUBECTL_WITH_CFG} rollout status deployment/istio-galley --timeout=2m -n istio-system
	@${KUBECTL_WITH_CFG} rollout status deployment/istio-sidecar-injector --timeout=2m -n istio-system
