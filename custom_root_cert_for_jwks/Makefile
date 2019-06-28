HOSTNAME := nginx.somewhereelse.svc.cluster.local

generate-cert:
	openssl req -new -newkey rsa:4096 -x509 -sha256 \
			-days 365 -nodes -out cert.crt -keyout key.key \
			-subj "/C=US/ST=Denial/L=Ether/O=Dis/CN=${HOSTNAME}"

create-secret:
	kubectl create secret generic nginx-cert --from-file=cert.crt --from-file=key.key -n somewhereelse

create:
	kubectl apply -f jwks-server.yaml -n somewhereelse
	# httbin is deployed to default namespace. you need to have automatic sidecar injection enabled!
	kubectl apply -f httpbin.yaml
	# sleep also goes to default
	kubectl apply -f sleep.yaml

delete:
	kubectl delete -f jwks-server.yaml -n somewhereelse
	kubectl delete -f httpbin.yaml

test:
	@echo This request should fail:
	@kubectl exec $(shell kubectl get pods -A --field-selector "status.phase=Running" -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- \
		curl -I httpbin.default.svc.cluster.local:80/headers \
		2> /dev/null | grep HTTP
	@echo This request should pass:
	@kubectl exec $(shell kubectl get pods -A --field-selector "status.phase=Running" -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- \
		curl -I httpbin.default.svc.cluster.local:80/headers \
		--header 'Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IkRIRmJwb0lVcXJZOHQyenBBMnFYZkNtcjVWTzVaRXI0UnpIVV8tZW52dlEiLCJ0eXAiOiJKV1QifQ.eyJleHAiOjQ2ODU5ODk3MDAsImZvbyI6ImJhciIsImlhdCI6MTUzMjM4OTcwMCwiaXNzIjoidGVzdGluZ0BzZWN1cmUuaXN0aW8uaW8iLCJzdWIiOiJ0ZXN0aW5nQHNlY3VyZS5pc3Rpby5pbyJ9.CfNnxWP2tcnR9q0vxyxweaF3ovQYHYZl82hAUsn21bwQd9zP7c-LS9qd_vpdLG4Tn1A15NxfCjp5f7QNBUo-KC9PJqYpgGbaXhaGx7bEdFWjcwv3nZzvc7M__ZpaCERdwU7igUmJqYGBYQ51vr2njU9ZimyKkfDe3axcyiBZde7G6dabliUosJvvKOPcKIWPccCgefSj_GNfwIip3-SsFdlR7BtbVUcqR-yv-XOxJ3Uc1MI0tz3uMiiZcyPV7sNCU4KRnemRIMHVOfuvHsU60_GhGbiSFzgPTAa9WTltbnarTbxudb_YEOx12JiwYToeX0DCPb43W1tzIBxgm8NxUg' \
		2> /dev/null  | grep HTTP