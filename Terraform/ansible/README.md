# Ansible plays (Terraform/ansible)

Run the provided playbooks to apply Kubernetes manifests via `kubectl` on the remote host.

Examples:

```bash
cd Terraform/ansible
ansible-playbook -i hosts.ini deploy_backend.yml -e "version=latest"
ansible-playbook -i hosts.ini deploy_frontend.yml -e "version=latest"
```

Notes:
- `hosts.ini` contains the `server` host and SSH connection info.
- Playbooks use `kubectl` commands; ensure `kubectl` and kubeconfig are available on the remote host.
