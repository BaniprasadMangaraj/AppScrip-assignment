
This project helps you **automate server setup** using Ansible. You can install tools like Java, Jenkins, Docker, Trivy, AWS CLI, Helm, kubectl, and ArgoCD on remote servers easily.

---

## 📁 Folder Structure

```
ansible/
├── inventories/
│   └── dev              # Inventory file with your server IP/hostname
├── playbooks/
│   └── install-all.yml  # Playbook with installation steps
```

---

## ✅ Steps to Use

### 1. Go to the Ansible Folder

```bash
cd ansible
```

---

### 2. Add Your Server in Inventory File

Edit the `inventories/dev` file and add your server like this:

```
[dev_servers]
your-server-ip ansible_user=your-user ansible_ssh_private_key_file=path-to-your-private-key
```

Example:
```
[dev_servers]
13.233.123.45 ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/id_rsa
```

---

### 3. Check Connection to Server

Run this command to check if Ansible can connect:

```bash
ansible -i inventories/dev dev_servers -m ping
```

✅ If it works, you’ll see:
```
13.233.123.45 | SUCCESS => { "ping": "pong" }
```

---

### 4. Run the Playbook

Now install all the tools with one command:

```bash
ansible-playbook -i inventories/dev playbooks/install-all.yml
```

This will:
- Update your system
- Install Java, Jenkins, Docker, Trivy
- Install AWS CLI, Helm, kubectl, and ArgoCD

---
