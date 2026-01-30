#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# --- Configuration ---
IMAGE_NAME="kube-startup-cpu-boost"
DOCKER_REPO="docker.io/lazyken/kube-startup-cpu-boost"
TAG="dev"
FULL_IMG="${DOCKER_REPO}:${TAG}"
NAMESPACE="kube-startup-cpu-boost-system" 
NAME_PATTERN="kube-startup-cpu-boost"

# --- ANSI Color Codes ---
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Logging Functions ---

log_step() {
    echo -e "\n${BLUE}================================================================${NC}"
    echo -e "${CYAN}>> $1${NC}"
    echo -e "${BLUE}================================================================${NC}"
}

log_info() {
    echo -e "${CYAN}ℹ️  INFO: $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ SUCCESS: $1${NC}"
}

log_error() {
    echo -e "${RED}❌ ERROR: $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
}

# --- Operations ---

function clean_local_node() {
    log_step "Checking for existing images in cluster (crictl)"

    # Using grep/awk is more robust across crictl versions than regex filters
    IMG_IDS=$(sudo crictl images | grep "${IMAGE_NAME}" | awk '{print $3}')

    if [ -n "$IMG_IDS" ]; then
        log_warn "Found existing images. Deleting from runtime..."
        # xargs -r prevents running the command if input is empty
        echo "$IMG_IDS" | xargs -r sudo crictl rmi || log_warn "Could not delete some images (might be in use)"
        log_success "Clean up complete."
    else
        log_info "No existing images found in crictl."
    fi
}

function load_image_to_runtime() {
    log_step "Loading Docker image into Container Runtime (crictl/containerd)"
    
    # We pipe 'docker save' directly into 'ctr import'
    # NOTE: This assumes you are using containerd (standard for crictl users).
    # We use namespace 'k8s.io' because that is where Kubernetes looks for images.
    
    if docker save "${FULL_IMG}" | sudo ctr -n k8s.io images import -; then
        log_success "Image imported to runtime successfully."
    else
        log_error "Failed to load image. Ensure 'ctr' is installed and you have sudo."
        exit 1
    fi
}

function delete_old_pods() {
    log_step "Deleting old controller pods"
    
    local MATCHING_PODS=$(kubectl get pods -n "${NAMESPACE}" --no-headers 2>/dev/null | grep "${NAME_PATTERN}" | awk '{print $1}')

    if [ -n "$MATCHING_PODS" ]; then
        log_info "Found the following pods in namespace '${NAMESPACE}':"
        echo "$MATCHING_PODS"
        
        log_info "Deleting them to force a restart..."
        echo "$MATCHING_PODS" | xargs -r kubectl delete pod -n "${NAMESPACE}"
        
        log_success "Old pods deleted."
    else
        log_info "No pods found containing '${NAME_PATTERN}' in namespace '${NAMESPACE}'. Skipping delete."
    fi
}

# --- Main Execution ---

MODE="$1"

if [[ "$MODE" != "full" && "$MODE" != "local" ]]; then
    log_error "Invalid or missing argument."
    log_info "Usage:"
    log_info "  ./build.sh full   (Build -> Push -> Deploy)"
    log_info "  ./build.sh local  (Build -> Load to crictl -> Deploy)"
    exit 1
fi

# 1. Clean up local crictl cache (Needed for both modes to ensure freshness)
clean_local_node

# 2. Build Docker Image (Needed for both)
log_step "Building Docker Image"
if make docker-build IMG="${FULL_IMG}"; then
    log_success "Docker build successful"
else
    log_error "Docker build failed"
    exit 1
fi

# 3. Handle Push vs Local Load
if [ "$MODE" == "full" ]; then
    log_step "Pushing Image to DockerHub"
    if docker push "${FULL_IMG}"; then
        log_success "Image pushed to ${FULL_IMG}"
    else
        log_error "Docker push failed. Run 'docker login'?"
        exit 1
    fi
elif [ "$MODE" == "local" ]; then
    # Skip push, load directly
    load_image_to_runtime
fi

# 4. Delete Old Pods
delete_old_pods

# 5. Deploy Manifests
log_step "Deploying to Kubernetes Cluster"
if make deploy IMG="${FULL_IMG}"; then
    log_success "Manifests applied to cluster"
else
    log_error "Make deploy failed"
    exit 1
fi

# 6. Final Status
echo -e "\n${GREEN}🚀 COMPLETE: Workflow ($MODE) finished successfully!${NC}"
log_info "Image: ${FULL_IMG}"
log_info "Namespace: ${NAMESPACE}\n"