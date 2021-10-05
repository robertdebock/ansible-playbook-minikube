# Ansible playbook for Minikube

## Setup

The state of the used roles:

|Role name|GitHub Action|GitLab CI|Version|
|---------|-------------|---------|-------|
|[bootstrap](https://galaxy.ansible.com/robertdebock/bootstrap)|[![github](https://github.com/robertdebock/ansible-role-bootstrap/workflows/Ansible%20Molecule/badge.svg)](https://github.com/robertdebock/ansible-role-bootstrap/actions)|[![gitlab](https://gitlab.com/robertdebock/ansible-role-bootstrap/badges/master/pipeline.svg)](https://gitlab.com/robertdebock/ansible-role-bootstrap)|[![version](https://img.shields.io/github/commits-since/robertdebock/ansible-role-bootstrap/latest.svg)](https://github.com/robertdebock/ansible-role-bootstrap/releases)|
|[docker](https://galaxy.ansible.com/robertdebock/docker)|[![github](https://github.com/robertdebock/ansible-role-docker/workflows/Ansible%20Molecule/badge.svg)](https://github.com/robertdebock/ansible-role-docker/actions)|[![gitlab](https://gitlab.com/robertdebock/ansible-role-docker/badges/master/pipeline.svg)](https://gitlab.com/robertdebock/ansible-role-docker)|[![version](https://img.shields.io/github/commits-since/robertdebock/ansible-role-docker/latest.svg)](https://github.com/robertdebock/ansible-role-docker/releases)|
|[core_dependencies](https://galaxy.ansible.com/robertdebock/core_dependencies)|[![github](https://github.com/robertdebock/ansible-role-core_dependencies/workflows/Ansible%20Molecule/badge.svg)](https://github.com/robertdebock/ansible-role-core_dependencies/actions)|[![gitlab](https://gitlab.com/robertdebock/ansible-role-core_dependencies/badges/master/pipeline.svg)](https://gitlab.com/robertdebock/ansible-role-core_dependencies)|[![version](https://img.shields.io/github/commits-since/robertdebock/ansible-role-core_dependencies/latest.svg)](https://github.com/robertdebock/ansible-role-core_dependencies/releases)|
|[buildtools](https://galaxy.ansible.com/robertdebock/buildtools)|[![github](https://github.com/robertdebock/ansible-role-buildtools/workflows/Ansible%20Molecule/badge.svg)](https://github.com/robertdebock/ansible-role-buildtools/actions)|[![gitlab](https://gitlab.com/robertdebock/ansible-role-buildtools/badges/master/pipeline.svg)](https://gitlab.com/robertdebock/ansible-role-buildtools)|[![version](https://img.shields.io/github/commits-since/robertdebock/ansible-role-buildtools/latest.svg)](https://github.com/robertdebock/ansible-role-buildtools/releases)|
|[epel](https://galaxy.ansible.com/robertdebock/epel)|[![github](https://github.com/robertdebock/ansible-role-epel/workflows/Ansible%20Molecule/badge.svg)](https://github.com/robertdebock/ansible-role-epel/actions)|[![gitlab](https://gitlab.com/robertdebock/ansible-role-epel/badges/master/pipeline.svg)](https://gitlab.com/robertdebock/ansible-role-epel)|[![version](https://img.shields.io/github/commits-since/robertdebock/ansible-role-epel/latest.svg)](https://github.com/robertdebock/ansible-role-epel/releases)|
|[python_pip](https://galaxy.ansible.com/robertdebock/python_pip)|[![github](https://github.com/robertdebock/ansible-role-python_pip/workflows/Ansible%20Molecule/badge.svg)](https://github.com/robertdebock/ansible-role-python_pip/actions)|[![gitlab](https://gitlab.com/robertdebock/ansible-role-python_pip/badges/master/pipeline.svg)](https://gitlab.com/robertdebock/ansible-role-python_pip)|[![version](https://img.shields.io/github/commits-since/robertdebock/ansible-role-python_pip/latest.svg)](https://github.com/robertdebock/ansible-role-python_pip/releases)|
|[users](https://galaxy.ansible.com/robertdebock/users)|[![github](https://github.com/robertdebock/ansible-role-users/workflows/Ansible%20Molecule/badge.svg)](https://github.com/robertdebock/ansible-role-users/actions)|[![gitlab](https://gitlab.com/robertdebock/ansible-role-users/badges/master/pipeline.svg)](https://gitlab.com/robertdebock/ansible-role-users)|[![version](https://img.shields.io/github/commits-since/robertdebock/ansible-role-users/latest.svg)](https://github.com/robertdebock/ansible-role-users/releases)|
|[software](https://galaxy.ansible.com/robertdebock/software)|[![github](https://github.com/robertdebock/ansible-role-software/workflows/Ansible%20Molecule/badge.svg)](https://github.com/robertdebock/ansible-role-software/actions)|[![gitlab](https://gitlab.com/robertdebock/ansible-role-software/badges/master/pipeline.svg)](https://gitlab.com/robertdebock/ansible-role-software)|[![version](https://img.shields.io/github/commits-since/robertdebock/ansible-role-software/latest.svg)](https://github.com/robertdebock/ansible-role-software/releases)|


1. Download the Ansible roles:

```shell
ansible-galaxy install -r roles/requirements.yml
```

2. Download the terraform providers and modules:

```shell
cd terraform
terraform init
```

3. Set the DigitalOcean and CloudFlare credentials:

```shell
export TF_VAR_do_token="REPLACE_ME_WITH_THE_DO_TOKEN"
export TF_VAR_cloudflare_api_token="REPLACE_ME_WITH_THE_CF_TOKEN"
```

## Installation

Apply the playbook:

```shell
./playbook.yml
```

```shell
ssh -i ssh_keys/id_rsa root@${machine}
su - minikube
```

You're now ready to follow [HashiCorps tutorial on kubernetes with Certmanager](https://learn.hashicorp.com/tutorials/vault/kubernetes-cert-manager).

## Manual steps follow

```shell
minikube start
# minikube kubectl -- get pods -A
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm install vault hashicorp/vault --set "injector.enabled=false"
# helm status vault
# helm get manifest vault
# kubectl get pods
# kubectl get services
kubectl exec vault-0 -- vault operator init \
  -key-shares=1 \
  -key-threshold=1 \
  -format=json > init-keys.json
# cat init-keys.json | jq -r ".unseal_keys_b64[]"
VAULT_UNSEAL_KEY=$(cat init-keys.json | jq -r ".unseal_keys_b64[]")
kubectl exec vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY
# cat init-keys.json | jq -r ".root_token"
VAULT_ROOT_TOKEN=$(cat init-keys.json | jq -r ".root_token")
kubectl exec vault-0 -- vault login $VAULT_ROOT_TOKEN

kubectl exec --stdin=true --tty=true vault-0 -- /bin/sh

vault secrets enable pki
vault secrets tune -max-lease-ttl=8760h pki

vault write pki/root/generate/internal common_name=example.com ttl=8760h

vault write pki/config/urls \
  issuing_certificates="http://vault.default:8200/v1/pki/ca" \
  crl_distribution_points="http://vault.default:8200/v1/pki/crl"

vault write pki/roles/example-dot-com \
  allowed_domains=example.com \
  allow_subdomains=true \
  max_ttl=72h

vault policy write pki - <<EOF
path "pki*"                        { capabilities = ["read", "list"] }
path "pki/roles/example-dot-com"   { capabilities = ["create", "update"] }
path "pki/sign/example-dot-com"    { capabilities = ["create", "update"] }
path "pki/issue/example-dot-com"   { capabilities = ["create"] }
EOF

vault auth enable kubernetes

vault write auth/kubernetes/config \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

exit

kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.14.3/cert-manager.crds.yaml

kubectl create namespace cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager \
    --namespace cert-manager \
    --version v0.14.3 \
   jetstack/cert-manager

# kubectl get pods --namespace cert-manager

kubectl create serviceaccount issuer

# kubectl get secrets

ISSUER_SECRET_REF=$(kubectl get serviceaccount issuer -o json | jq -r ".secrets[].name")

cat > vault-issuer.yaml <<EOF
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: vault-issuer
  namespace: default
spec:
  vault:
    server: http://vault.default
    path: pki/sign/example-dot-com
    auth:
      kubernetes:
        mountPath: /v1/auth/kubernetes
        role: issuer
        secretRef:
          name: $ISSUER_SECRET_REF
          key: token
EOF

kubectl apply --filename vault-issuer.yaml

cat > example-com-cert.yaml <<EOF
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: example-com
  namespace: default
spec:
  secretName: example-com-tls
  issuerRef:
    name: vault-issuer
  commonName: www.example.com
  dnsNames:
  - www.example.com
EOF

kubectl apply --filename example-com-cert.yaml

# kubectl describe certificate.cert-manager example-com
