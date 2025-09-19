#!/usr/bin/env bash
# scripts/bootstrap.sh
# Usage:
#  sudo bash /vagrant/bootstrap.sh master <MASTER_IP> <WORKER_COUNT>
#  sudo bash /vagrant/bootstrap.sh worker <MASTER_IP> <WORKER_COUNT>

set -o errexit
set -o nounset
set -o pipefail

ROLE=${1:-}
MASTER_IP=${2:-192.168.56.10}
WORKER_COUNT=${3:-3}
VAGRANT_MOUNT="/vagrant"
JOIN_SCRIPT_PATH="${VAGRANT_MOUNT}/kubeadm_join.sh"
ADMIN_CONF_HOST_PATH="${VAGRANT_MOUNT}/admin.conf"
LOGPREFIX="[$(hostname) ${ROLE}]"

echo "${LOGPREFIX} Starting bootstrap for role=${ROLE} master=${MASTER_IP} workers=${WORKER_COUNT}"

# Helper: log
log() {
  echo "${LOGPREFIX} $*"
}

# Ensure uploaded scripts have correct line endings (fix CRLF issues)
sanitize_uploaded() {
  if command -v dos2unix >/dev/null 2>&1; then
    dos2unix "${VAGRANT_MOUNT}/bootstrap.sh" >/dev/null 2>&1 || true
  else
    # try to install dos2unix quickly
    apt-get update -y || true
    apt-get install -y -q dos2unix >/dev/null 2>&1 || true
    if command -v dos2unix >/dev/null 2>&1; then
      dos2unix "${VAGRANT_MOUNT}/bootstrap.sh" >/dev/null 2>&1 || true
    else
      # fallback: strip CR (\r)
      sed -i 's/\r$//' "${VAGRANT_MOUNT}/bootstrap.sh" >/dev/null 2>&1 || true
    fi
  fi
}

# Common: disable swap, sysctl net.bridge calls, remove apt locks
prepare_host() {
  log "Preparing host: disable swap and configure sysctl"
  swapoff -a || true
  sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab || true

  # Load required kernel modules
  modprobe br_netfilter || true
  echo 'br_netfilter' >> /etc/modules-load.d/k8s.conf || true

  cat > /etc/sysctl.d/k8s.conf <<'EOF'
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
  sysctl --system >/dev/null 2>&1 || true
}

# Install containerd + kubeadm/kubelet/kubectl
install_kube_prereqs() {
  log "Installing containerd and kube packages"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y

  # Basic utilities
  apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common

  # Add Kubernetes apt repo
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

  # Install containerd
  apt-get update -y
  apt-get install -y containerd

  # Configure containerd default cgroup driver (systemd)
  mkdir -p /etc/containerd
  containerd config default >/etc/containerd/config.toml
  # set SystemdCgroup = true in config if not already
  sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml || true
  # Also ensure the correct cgroup driver is set
  sed -i 's/cgroupfs/systemd/' /etc/containerd/config.toml || true
  systemctl restart containerd
  systemctl enable containerd

  # Install kube packages and hold them to avoid accidental upgrades
  apt-get update -y
  apt-get install -y kubelet kubeadm kubectl
  apt-mark hold kubelet kubeadm kubectl
  systemctl enable kubelet
}

# Master initialization
init_master() {
  log "Initializing Kubernetes control plane on master"
  # Use kubeadm to init. Use advertise address = MASTER_IP
  if ! kubeadm init --apiserver-advertise-address="${MASTER_IP}" --pod-network-cidr=192.168.0.0/16 --ignore-preflight-errors=Swap; then
    log "ERROR: kubeadm init failed"
    exit 1
  fi

  # Export admin.conf to /vagrant so host can pick it up
  if [ -f /etc/kubernetes/admin.conf ]; then
    cp /etc/kubernetes/admin.conf "${ADMIN_CONF_HOST_PATH}"
    chown 1000:1000 "${ADMIN_CONF_HOST_PATH}" || true
    log "Wrote admin.conf to ${ADMIN_CONF_HOST_PATH}"
  else
    log "Warning: /etc/kubernetes/admin.conf not found after kubeadm init"
  fi

  # Install a CNI plugin (Calico) - minimal manifest apply; adapt if you prefer a different CNI
  log "Applying Calico CNI"
  # use the Calico manifest from official docs (pinned to a stable version is recommended)
  if ! kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f "https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml"; then
    log "ERROR: Failed to apply Calico CNI"
    exit 1
  fi
  
  # Wait for Calico pods to be ready
  log "Waiting for Calico CNI to be ready..."
  kubectl --kubeconfig=/etc/kubernetes/admin.conf wait --for=condition=ready pod -l k8s-app=calico-node -n kube-system --timeout=300s || true

  # Wait for critical control plane static pods to be running
  log "Waiting for kube-apiserver, controller-manager, scheduler and etcd pods to be running..."
  for i in {1..120}; do
    # Check if API server is responding
    if curl -k --max-time 3 https://${MASTER_IP}:6443/healthz >/dev/null 2>&1; then
      log "API server /healthz is reachable"
      # Additional check: ensure core pods are running
      ready_pods=$(kubectl --kubeconfig=/etc/kubernetes/admin.conf -n kube-system get pods --no-headers 2>/dev/null | grep -E "(kube-apiserver|kube-controller-manager|kube-scheduler|etcd)" | grep "Running" | wc -l || true)
      if [ "${ready_pods}" -ge 4 ]; then
        log "All core control plane pods are running"
        break
      fi
    fi
    log "Waiting for control plane to be ready... (attempt ${i}/120)"
    sleep 5
  done

  # Create a fresh join command and write to /vagrant/kubeadm_join.sh
  # This prints the join command (token + discovery hash)
  log "Creating kubeadm join command and writing to ${JOIN_SCRIPT_PATH}"
  if ! kubeadm token create --print-join-command > "${JOIN_SCRIPT_PATH}"; then
    log "ERROR: Failed to create join command"
    exit 1
  fi
  chmod +x "${JOIN_SCRIPT_PATH}"
  chown 1000:1000 "${JOIN_SCRIPT_PATH}" || true

  # Final validation: ensure cluster is ready for worker nodes
  log "Performing final cluster validation..."
  kubectl --kubeconfig=/etc/kubernetes/admin.conf get nodes || true
  kubectl --kubeconfig=/etc/kubernetes/admin.conf get pods -n kube-system || true
  
  log "Master initialization complete."
}

# Worker wait loop: wait for join script and for API to be ready and cluster-info configmap present
wait_for_api_and_join() {
  # Wait for join script to appear
  log "Worker: waiting for join script at ${JOIN_SCRIPT_PATH} (timeout 600s)"
  start_ts=$(date +%s)
  timeout=600
  while [ ! -f "${JOIN_SCRIPT_PATH}" ]; do
    now=$(date +%s)
    if [ $((now - start_ts)) -ge ${timeout} ]; then
      log "Timed out waiting for join script."
      return 1
    fi
    sleep 2
  done
  log "Worker: found join script."

  # Sanitize join script line endings (in case Windows uploaded)
  sed -i 's/\r$//' "${JOIN_SCRIPT_PATH}" || true
  chmod +x "${JOIN_SCRIPT_PATH}"

  # Wait for API /healthz to be healthy (short window), then cluster-info ConfigMap to be readable
  log "Worker: waiting for API server https://${MASTER_IP}:6443/healthz to be healthy (timeout 600s)..."
  start_ts=$(date +%s)
  timeout=600
  while true; do
    if curl -k --max-time 3 --connect-timeout 3 "https://${MASTER_IP}:6443/healthz" >/dev/null 2>&1; then
      log "API server healthy — now waiting for cluster-info ConfigMap endpoint to be available..."
      break
    fi
    now=$(date +%s)
    elapsed=$((now - start_ts))
    if [ ${elapsed} -ge ${timeout} ]; then
      log "Timed out waiting for API /healthz"
      return 1
    fi
    log "Worker: waiting for API server... (${elapsed}s elapsed)"
    sleep 5
  done

  # Wait for cluster-info configmap to return 200
  start_ts=$(date +%s)
  while true; do
    # use curl to check the cluster-info path
    if curl -k --max-time 10 --connect-timeout 5 -sS -f "https://${MASTER_IP}:6443/api/v1/namespaces/kube-public/configmaps/cluster-info" >/dev/null 2>&1; then
      log "cluster-info ConfigMap is available"
      break
    fi
    now=$(date +%s)
    if [ $((now - start_ts)) -ge ${timeout} ]; then
      log "Timed out waiting for cluster-info ConfigMap. Giving up."
      return 1
    fi
    sleep 3
  done

  # Run the join script with retries (kubeadm join can fail early if transient), make sure to run as root
  tries=0
  maxtries=6
  while [ $tries -lt $maxtries ]; do
    tries=$((tries + 1))
    log "Attempt ${tries}/${maxtries}: running join script..."
    set +e
    bash "${JOIN_SCRIPT_PATH}" && rc=$? || rc=$?
    set -e
    if [ ${rc} -eq 0 ]; then
      log "Join succeeded."
      return 0
    fi
    log "Join attempt ${tries} failed (rc=${rc}). Sleep and retry."
    sleep 5
  done

  log "Join failed after ${maxtries} attempts."
  return 1
}

main() {
  # sanitize uploaded bootstrap for CRLF issues
  if [ -f "${VAGRANT_MOUNT}/bootstrap.sh" ]; then
    sanitize_uploaded
  fi

  prepare_host
  install_kube_prereqs

  if [ "${ROLE}" = "master" ]; then
    init_master
    # write a short status file so host can detect readiness
    echo "MASTER_READY=1" > "${VAGRANT_MOUNT}/master_ready.txt"
    log "Master ready file written to ${VAGRANT_MOUNT}/master_ready.txt"
  elif [ "${ROLE}" = "worker" ]; then
    wait_for_api_and_join || {
      log "Worker bootstrap failed (see logs)."
      exit 1
    }
  else
    log "Unknown role '${ROLE}' - exiting."
    exit 2
  fi
}

main "$@"
