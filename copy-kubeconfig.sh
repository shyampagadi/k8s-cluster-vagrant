#!/bin/bash
# copy-kubeconfig.sh - Copy kubeconfig from vagrant cluster to current directory and global kubectl config

set -e

CURRENT_DIR=$(pwd)
KUBECONFIG_LOCAL="$CURRENT_DIR/kubeconfig"
KUBECONFIG_BACKUP="$CURRENT_DIR/kubeconfig.backup.$(date +%Y%m%d_%H%M%S)"

# Windows paths for global kubectl config
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || -n "$WINDIR" ]]; then
    # Windows/Git Bash environment
    KUBE_DIR="$HOME/.kube"
    KUBECONFIG_GLOBAL="$KUBE_DIR/config"
    KUBECONFIG_GLOBAL_BACKUP="$KUBE_DIR/config.backup.$(date +%Y%m%d_%H%M%S)"
else
    # Linux/Mac environment
    KUBE_DIR="$HOME/.kube"
    KUBECONFIG_GLOBAL="$KUBE_DIR/config"
    KUBECONFIG_GLOBAL_BACKUP="$KUBE_DIR/config.backup.$(date +%Y%m%d_%H%M%S)"
fi

echo "🔧 Copying kubeconfig from vagrant cluster..."

# Check if admin.conf exists
if [ ! -f "admin.conf" ]; then
    echo "❌ admin.conf not found in current directory."
    echo "   Make sure you've run 'vagrant up' and the master node has completed initialization."
    exit 1
fi

# Copy to current directory
echo "📁 Copying to current directory..."
if [ -f "$KUBECONFIG_LOCAL" ]; then
    echo "📦 Backing up existing kubeconfig to $KUBECONFIG_BACKUP"
    cp "$KUBECONFIG_LOCAL" "$KUBECONFIG_BACKUP"
fi
cp admin.conf "$KUBECONFIG_LOCAL"

# Copy to global kubectl config location
echo "🌐 Copying to global kubectl config location..."
mkdir -p "$KUBE_DIR"
if [ -f "$KUBECONFIG_GLOBAL" ]; then
    echo "📦 Backing up existing global kubeconfig to $KUBECONFIG_GLOBAL_BACKUP"
    cp "$KUBECONFIG_GLOBAL" "$KUBECONFIG_GLOBAL_BACKUP"
fi
cp admin.conf "$KUBECONFIG_GLOBAL"

echo "✅ Kubeconfig copied successfully!"
echo ""
echo "📍 Local copy: $KUBECONFIG_LOCAL"
echo "📍 Global copy: $KUBECONFIG_GLOBAL"
echo ""
echo "🚀 You can now use kubectl commands from anywhere:"
echo "   kubectl get nodes"
echo "   kubectl get pods -A"
echo "   kubectl get services"
echo ""
echo "💡 To use the local copy instead:"
echo "   kubectl --kubeconfig=$KUBECONFIG_LOCAL get nodes"
echo ""
echo "💡 To restore your previous global config:"
echo "   cp $KUBECONFIG_GLOBAL_BACKUP $KUBECONFIG_GLOBAL"
