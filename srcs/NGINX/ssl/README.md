Place your TLS certificate and private key here:

- server.crt — PEM-encoded certificate (or full chain)
- server.key — PEM-encoded private key

For local testing you can generate a self-signed cert:

openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
  -keyout server.key -out server.crt \
  -subj "/CN=localhost"
