generate-cert:
	openssl req -new -newkey rsa:4096 -x509 -sha256 \
			-days 365 -nodes -out cert.crt -keyout key.key \
			-subj "/C=US/ST=Denial/L=Ether/O=Dis/CN=jwks-server"
