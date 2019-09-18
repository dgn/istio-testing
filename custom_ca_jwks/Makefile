HOSTNAME := nginx.somewhereelse.svc.cluster.local

NS := default
NS2 := somewhereelse

all: delete-cluster create-cluster reinstall-istio create-nginx create test

include ../common.mk

generate-cert:
	openssl req -new -newkey rsa:4096 -x509 -sha256 \
			-days 365 -nodes -out cert.crt -keyout key.key \
			-subj "/C=US/ST=Denial/L=Ether/O=Dis/CN=${HOSTNAME}"

create-secret:
	@${KUBECTL_WITH_CFG} create namespace ${NS2} || echo Namespace already exists
	@${KUBECTL_WITH_CFG} create secret generic nginx-cert --from-file=cert.crt --from-file=key.key -n ${NS2} || echo exists

create-nginx: create-secret
	@${KUBECTL_WITH_CFG} create namespace ${NS2} || echo Namespace already exists
	@${KUBECTL_WITH_CFG} apply -f jwks-server.yaml -n ${NS2}
	@${KUBECTL_WITH_CFG} rollout status --timeout=2m deployment/nginx-deployment -n ${NS2}

create: 
	@${KUBECTL_WITH_CFG} label ns default istio-injection=enabled || echo .
	@${KUBECTL_WITH_CFG} apply -f httpbin.yaml -n ${NS}
	@${KUBECTL_WITH_CFG} apply -f sleep.yaml -n ${NS}
	@${KUBECTL_WITH_CFG} rollout status --timeout=2m deployment/httpbin -n ${NS}
	@${KUBECTL_WITH_CFG} rollout status --timeout=2m deployment/sleep -n ${NS}

delete: 
	@${KUBECTL_WITH_CFG} delete -f httpbin.yaml -n ${NS}
	@${KUBECTL_WITH_CFG} delete -f sleep.yaml -n ${NS}

delete-nginx: delete-secret
	@${KUBECTL_WITH_CFG} delete -f jwks-server.yaml -n ${NS2}

delete-secret:
	@${KUBECTL_WITH_CFG} delete secret nginx-cert -n ${NS2}

test:
	@printf "Requesting without JWT: Expected 401, got "
	@${KUBECTL_WITH_CFG} exec $(shell ${KUBECTL_WITH_CFG} get pods -A --field-selector "status.phase=Running" -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c sleep -- \
		curl -s -o /dev/null -w "%{http_code}\n" httpbin:80/headers
	@printf "Requesting with JWT:    Expected 200, got "
	@${KUBECTL_WITH_CFG} exec $(shell ${KUBECTL_WITH_CFG} get pods -A --field-selector "status.phase=Running" -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c sleep -- \
		curl -s -o /dev/null -w "%{http_code}\n" httpbin:80/headers \
		--header 'Authorization: Bearer $(shell cat token.jwt)'

build-pilot:
	@cd ${ISTIO}/istio && make pilot docker.pilot && docker push ${HUB}/pilot:${TAG}

reinstall-istio: build-pilot
	@${KUBECTL_WITH_CFG} create namespace istio-system || echo Namespace already exists
	@cd ${ISTIO}/istio && helm template install/kubernetes/helm/istio-init --name istio-init --namespace istio-system \
		| ${KUBECTL_WITH_CFG} apply -f -
	@sleep 60
	@cd ${ISTIO}/istio && helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
		--set-file pilot.jwksResolverExtraRootCA=${CURRENTDIR}/cert.crt \
		--set pilot.image=${HUB}/pilot:${TAG} \
		| ${KUBECTL_WITH_CFG} apply -f -
	@${KUBECTL_WITH_CFG} rollout status deployment/istio-pilot --timeout=2m -n istio-system
	@${KUBECTL_WITH_CFG} rollout status deployment/istio-galley --timeout=2m -n istio-system
	@${KUBECTL_WITH_CFG} rollout status deployment/istio-sidecar-injector --timeout=2m -n istio-system

