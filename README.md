# Linux user onboarding (lite)

## English

### Purpose

A short script that creates one key-only account inside a lab tree. It prints the same style of `ACTION` lines as the full pack and can apply them under `ONBOARD_ROOT`. It does not expire accounts, read a CSV, archive a home, or delete anything.

### Deliverables

- `deliverables/onboard-lite.sh` — one user, optional sudo, optional public key, dry-run or apply
- `examples/alice.pub` — public key commented `alice@example.com`
- `examples/lab/` — a small passwd, group, shadow, and skel so the script has something to edit

### Quick start

```bash
cp -a examples/lab /tmp/lite-lab
export ONBOARD_ROOT=/tmp/lite-lab
bash deliverables/onboard-lite.sh \
  --user alice --sudo --keys examples/alice.pub --dry-run
bash deliverables/onboard-lite.sh \
  --user alice --sudo --keys examples/alice.pub
```

`--live` and `--force-delete` exit 4. This build never edits the host.

Delivery time: instant download after purchase

### Requirements

- Bash 5, `awk`, GNU `date`
- `ONBOARD_ROOT` with `etc/passwd`, `etc/group`, `etc/shadow`, `etc/skel`, and `home/`

Time saved: saves ~15–20 min on the first dry-run of a new account. The full pack covers offboarding, archives, expiry, and CSV batches.

Full version: GUMROAD_URL

## 中文

### 用途

精简脚本只在实验树里创建一个仅公钥账号，支持 dry-run。不含过期日、CSV、家目录归档，也不会删除账号。

### 交付物

- `deliverables/onboard-lite.sh`
- `examples/alice.pub`（注释为 `alice@example.com`）
- `examples/lab/`（小型 passwd / group / shadow / skel）

### 快速开始

```bash
cp -a examples/lab /tmp/lite-lab
export ONBOARD_ROOT=/tmp/lite-lab
bash deliverables/onboard-lite.sh --user alice --sudo --keys examples/alice.pub --dry-run
```

`--live` 和 `--force-delete` 会直接退出。这个版本不会改主机。

交付时间：购买后即时下载。

### 环境

需要 Bash 5、`awk` 和 GNU `date`，以及带 `etc/` 和 `home/` 的 `ONBOARD_ROOT`。

省时：第一次演练大约省 15–20 分钟。完整版还有离职、归档、过期日和 CSV。

Full version: GUMROAD_URL
