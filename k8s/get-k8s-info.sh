#!/bin/bash
# Script to get Kubernetes pod and node information

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed"
    exit 1
fi

# get current k8s cluster info
get-info() {
    echo "Current Kubernetes context:"
    kubectl config current-context || {
        echo "Error: Failed to get current context"
        return 1
    }
    echo -e "\nCluster details:"
    kubectl cluster-info || {
        echo "Error: Failed to get cluster info" 
        return 1
    }
    echo -e "\nCurrent namespace:"
    kubectl config view --minify --output 'jsonpath={..namespace}' || {
        echo "Error: Failed to get current namespace"
        return 1
    }
    echo # Add newline after namespace
}

# set namespace
set-namespace(){
    echo "Available namespaces:"
    kubectl get namespaces
    read -p "Enter namespace: " namespace
    
    if [ -z "$namespace" ]; then
        echo "Error: namespace not provided"
        return 1
    fi
    echo -e "\nSetting namespace to: $namespace"
    kubectl config set-context --current --namespace=$namespace || {
        echo "Error: Failed to set namespace"
        return 1
    }
}

# get nodes and pods by search string
find-pods-on-node(){
    echo "Available nodes:"
    kubectl get nodes
    read -p "Enter node name: " node_name
    
    if [ -z "$node_name" ]; then
        echo "Error: node name not provided"
        return 1
    fi
    echo -e "\nPods on node $node_name:"
    kubectl get pods -o wide --all-namespaces | grep $node_name || {
        echo "No pods found on node $node_name"
        return 1
    }
}

find-node-for-pod(){
    read -p "Enter pod name: " pod_name
    
    if [ -z "$pod_name" ]; then
        echo "Error: pod name not provided" 
        return 1
    fi
    kubectl get pods -o wide --all-namespaces | grep $pod_name || {
        echo "Pod $pod_name not found"
        return 1
    }
}

# run netshoot for troubleshooting
run-netshoot-container() {
    kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot -- /bin/bash || {
        echo "Error: Failed to run netshoot container"
        return 1
    }
}

# get all non-normal events across all namespaces
get-error-events() {
    echo "Fetching all error events across clusters:"
    kubectl events -A | grep -v Normal || {
        echo "Error: Failed to get events"
        return 1
    }
}

# get resource usage for nodes and pods
get-resources() {
    echo "Node resource usage:"
    kubectl top node || {
        echo "Error: Failed to get node metrics"
        return 1
    }
    
    echo -e "\nPod resource usage (sorted by memory):"
    kubectl top pod --sort-by=memory --all-namespaces || {
        echo "Error: Failed to get pod metrics"
        return 1
    }

    echo -e "\nTotal resource usage across all pods:"
    kubectl top pod --all-namespaces | tail -n +2 | awk '
        BEGIN {cpu=0; mem=0}
        {
            cpu+=$3;
            gsub(/Mi/,"",$4);
            mem+=$4
        }
        END {
            printf "CPU: %.1fm (%.2f cores), Memory: %.1fMi (%.2f GB)\n", 
                cpu, 
                cpu/1000,
                mem,
                mem/1024
        }'
}

# Check if option was provided as command line argument
if [ -n "$1" ]; then
    option=$1
else
    echo "Select an option:"
    echo "get-info) Show current cluster info"
    echo "set-namespace) Set namespace"
    echo "find-pods-on-node) Get pods by node name"
    echo "find-node-for-pod) Get node by pod name" 
    echo "run-netshoot-container) Run netshoot"
    echo "get-error-events) Show error events"
    echo "get-resources) Show resource usage"
    read -p "Enter function name: " option
fi

case $option in
    get-info)
        get-info
        ;;
    set-namespace)
        set-namespace
        ;;
    find-pods-on-node)
        find-pods-on-node
        ;;
    find-node-for-pod)
        find-node-for-pod
        ;;
    run-netshoot-container)
        run-netshoot-container
        ;;
    get-error-events)
        get-error-events
        ;;
    get-resources)
        get-resources
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac
