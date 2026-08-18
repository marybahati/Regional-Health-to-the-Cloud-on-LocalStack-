# Linux VM setup (macOS — and why you cannot skip this)

LocalStack EC2 instances are **Docker containers on a Linux bridge network**. Docker Desktop on a Mac does **not** expose that bridge to your Mac, so the app would deploy and you still could not curl `/readyz`. LocalStack documents this: https://docs.localstack.cloud/aws/services/ec2/

So on a Mac you run a **small Linux virtual machine**, install Docker Engine **inside Linux**, and do all `make up` work there.

```
Your Mac  →  Lima Linux VM  →  Docker Engine  →  LocalStack + EC2 container
                 (this is the machine that can reach the app)
```

Windows users: use WSL2 with Docker Engine (not Docker Desktop), or a Linux VM. Same idea.

## 1. Install Lima on the Mac

Lima runs Linux VMs on macOS. Docs: https://lima-vm.io/docs/installation/

```bash
brew install lima
limactl --version
```

You need roughly **4 CPUs, 10 GB RAM, 32 GB disk** free for the VM (your Mac has to have that headroom).

## 2. Start the lab VM

From **this repo** (on the Mac):

```bash
cd /path/to/rehosting-capacity-lab
limactl start lima/regional-health.yaml
```

Wait until it prints `READY`. Check:

```bash
limactl list
```

`regional-health` should be `Running` with Docker.

Open a Linux shell:

```bash
limactl shell --workdir /home/bahati.guest regional-health
```

You are now **inside Linux**. `uname -a` should say `Linux`.

## 3. macOS Privacy and `Downloads`

macOS often blocks VMs from reading `~/Downloads`. If you cloned this repo into Downloads, copy it onto the **guest disk** (that disk is writable and not blocked):

**On the Mac:**

```bash
cd /path/to/rehosting-capacity-lab
tar cf - --exclude node_modules --exclude .terraform . \
  | limactl shell --workdir /home/bahati.guest regional-health -- \
    bash -lc 'mkdir -p rehosting-capacity-lab && tar xf - -C rehosting-capacity-lab'
```

**Inside the VM:**

```bash
limactl shell --workdir /home/bahati.guest/rehosting-capacity-lab regional-health
```

Better long-term: clone the repo under `~/nginx-microservices` or `~/src` on the Mac (Lima can read those), or work only from the guest copy.

## 4. Install tools **inside** the VM

You already have Docker (the VM template installs it). Install the rest:

```bash
bash scripts/install-vm-tools.sh
export PATH="$HOME/.local/bin:$PATH"
```

Or follow [Native Linux setup](setup-linux.md) from step 1 — you are on Ubuntu inside the VM.

Confirm:

```bash
uname -a          # must say Linux
docker ps         # must work without sudo
terraform version
```

## 5. Do not use Docker Desktop for `make up`

On the Mac, `docker ps` talking to Docker Desktop is the **wrong** daemon. Always:

```bash
limactl shell --workdir /home/bahati.guest/rehosting-capacity-lab regional-health
make up
```

## 6. Next

1. [Set up LocalStack](localstack.md) (still inside the VM)
2. [Set up Aiven MySQL](aiven-mysql.md) (browser on the Mac is fine)
3. [First run](first-run.md)
