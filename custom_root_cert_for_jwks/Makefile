HOSTNAME := nginx.somewhereelse.svc.cluster.local

generate-cert:
	openssl req -new -newkey rsa:4096 -x509 -sha256 \
			-days 365 -nodes -out cert.crt -keyout key.key \
			-subj "/C=US/ST=Denial/L=Ether/O=Dis/CN=${HOSTNAME}"

create-secret:
	kubectl create secret generic nginx-cert --from-file=cert.crt --from-file=key.key -n somewhereelse

create:
	kubectl apply -f deployment.yaml -n somewhereelse

delete:
	kubectl delete -f deployment.yaml -n somewhereelse
