all: make push-minikube

make:
	# build the binary
	go build -o whatsmyip

push-minikube:
	# build the container inside the Minikube docker environment
	@eval $$(minikube docker-env) ;\
	docker build . -t whatsmyip:latest

create:
	kubectl apply -f whatsmyip.yaml

delete:
	kubectl delete -f whatsmyip.yaml

push-local:
	# push to local registry
	podman build . -t whatsmyip:latest
	podman push whatsmyip:latest localhost:5000/whatsmyip:latest --tls-verify=false

envoy-config:
	# retrieves the envoy config and dumps it to a timestamped file
	kubectl exec $(shell kubectl get pods -l app=whatsmyip -o=jsonpath='{.items[0].metadata.name}') -c istio-proxy curl localhost:15000/config_dump | jq -SM . | tee envoy_config_$(shell date '+%s').json
