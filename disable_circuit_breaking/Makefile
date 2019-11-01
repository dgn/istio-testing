NS := default

all: delete-cluster create-cluster reinstall-istio create test

include ../common.mk

create: 
	@${KUBECTL_WITH_CFG} label ns ${NS} istio-injection=enabled || echo .
	@${KUBECTL_WITH_CFG} apply -f httpbin.yaml -n ${NS}
	@${KUBECTL_WITH_CFG} apply -f fortio.yaml -n ${NS}
	@${KUBECTL_WITH_CFG} rollout status --timeout=2m deployment/httpbin -n ${NS}
	@${KUBECTL_WITH_CFG} rollout status --timeout=2m deployment/fortio-deploy -n ${NS}

delete: 
	@${KUBECTL_WITH_CFG} delete -f httpbin.yaml -n ${NS}
	@${KUBECTL_WITH_CFG} delete -f fortio.yaml -n ${NS}

test:
	@${KUBECTL_WITH_CFG} exec -it $(shell ${KUBECTL_WITH_CFG} get pods -n ${NS} --field-selector "status.phase=Running" -l app=fortio -o jsonpath='{.items[0].metadata.name}') -c fortio /usr/bin/fortio -- load -c 2 -qps 1 -n 20 -loglevel Warning http://httpbin/headers
	@${KUBECTL_WITH_CFG} exec -it $(shell ${KUBECTL_WITH_CFG} get pods -n ${NS} --field-selector "status.phase=Running" -l app=fortio -o jsonpath='{.items[0].metadata.name}')  -c fortio /usr/bin/fortio -- load -c 3 -qps 0 -n 30 -loglevel Warning http://httpbin/headers

build-pilot:
	@cd ${ISTIO}/istio && make pilot docker.pilot && docker push ${HUB}/pilot:${TAG}

reinstall-istio: build-pilot
	@${KUBECTL_WITH_CFG} create namespace istio-system || echo Namespace already exists
	@cd ${ISTIO}/istio && helm template install/kubernetes/helm/istio-init --name istio-init --namespace istio-system \
		| ${KUBECTL_WITH_CFG} apply -f -
	@sleep 60
	@cd ${ISTIO}/istio && helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
		--set pilot.image=${HUB}/pilot:${TAG} \
		| ${KUBECTL_WITH_CFG} apply -f -
	@${KUBECTL_WITH_CFG} rollout status deployment/istio-pilot --timeout=2m -n istio-system
	@${KUBECTL_WITH_CFG} rollout status deployment/istio-galley --timeout=2m -n istio-system
	@${KUBECTL_WITH_CFG} rollout status deployment/istio-sidecar-injector --timeout=2m -n istio-system

