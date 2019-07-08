HOSTNAME := nginx.somewhereelse.svc.cluster.local
CURRENTDIR := ${PWD}

generate-cert:
	openssl req -new -newkey rsa:4096 -x509 -sha256 \
			-days 365 -nodes -out cert.crt -keyout key.key \
			-subj "/C=US/ST=Denial/L=Ether/O=Dis/CN=${HOSTNAME}"

create-secret:
	kubectl create secret generic nginx-cert --from-file=cert.crt --from-file=key.key -n somewhereelse

create:
	kubectl label namespace default istio-injection=enabled
	kubectl apply -f httpbin.yaml
	kubectl apply -f sleep.yaml
	kubectl apply -f jwks-server.yaml -n somewhereelse

delete:
	kubectl delete -f jwks-server.yaml -n somewhereelse
	kubectl delete -f httpbin.yaml

test:
	@printf "Requesting without JWT: Expected 401, got "
	@kubectl exec $(shell kubectl get pods -A --field-selector "status.phase=Running" -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c sleep -- \
		curl -s -o /dev/null -w "%{http_code}\n" httpbin.default.svc.cluster.local:80/headers
	@printf "Requesting with JWT:    Expected 200, got "
	@kubectl exec $(shell kubectl get pods -A --field-selector "status.phase=Running" -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c sleep -- \
		curl -s -o /dev/null -w "%{http_code}\n" httpbin.default.svc.cluster.local:80/headers \
		--header 'Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IkRIRmJwb0lVcXJZOHQyenBBMnFYZkNtcjVWTzVaRXI0UnpIVV8tZW52dlEiLCJ0eXAiOiJKV1QifQ.eyJleHAiOjQ2ODU5ODk3MDAsImZvbyI6ImJhciIsImlhdCI6MTUzMjM4OTcwMCwiaXNzIjoidGVzdGluZ0BzZWN1cmUuaXN0aW8uaW8iLCJzdWIiOiJ0ZXN0aW5nQHNlY3VyZS5pc3Rpby5pbyJ9.CfNnxWP2tcnR9q0vxyxweaF3ovQYHYZl82hAUsn21bwQd9zP7c-LS9qd_vpdLG4Tn1A15NxfCjp5f7QNBUo-KC9PJqYpgGbaXhaGx7bEdFWjcwv3nZzvc7M__ZpaCERdwU7igUmJqYGBYQ51vr2njU9ZimyKkfDe3axcyiBZde7G6dabliUosJvvKOPcKIWPccCgefSj_GNfwIip3-SsFdlR7BtbVUcqR-yv-XOxJ3Uc1MI0tz3uMiiZcyPV7sNCU4KRnemRIMHVOfuvHsU60_GhGbiSFzgPTAa9WTltbnarTbxudb_YEOx12JiwYToeX0DCPb43W1tzIBxgm8NxUg'

build-pilot:
	@cd ${ISTIO}/istio && make pilot docker.pilot && make push.docker.pilot

reinstall-istio: build-pilot
	@cd ${ISTIO}/istio && helm delete --purge istio || echo Istio not yet installed. Installing now
	@cd ${ISTIO}/istio && helm install install/kubernetes/helm/istio --name istio --namespace istio-system \
		--values install/kubernetes/helm/istio/values-istio-demo.yaml \
		--set-file pilot.jwksCustomRootCa=${CURRENTDIR}/cert.crt \
		--set pilot.image=${HUB}/pilot:${TAG}
