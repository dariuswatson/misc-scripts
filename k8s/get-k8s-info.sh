#!/bin/bash
# Script to get Kubernetes pod and node information

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed"
    exit 1
fi

# get current k8s cluster info
get_current_cluster() {
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
}

# set namespace
set_namespace(){
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
find_pods_on_node(){
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

find_node_for_pod(){
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
run_netshoot_container() {
    kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot -- /bin/bash || {
        echo "Error: Failed to run netshoot container"
        return 1
    }
}

# get all non-normal events across all namespaces
get_error_events() {
    echo "Fetching all error events across clusters:"
    kubectl events -A | grep -v Normal || {
        echo "Error: Failed to get events"
        return 1
    }
}

# get resource usage for nodes and pods
get_resources() {
    echo "Node resource usage:"
    kubectl top node || {
        echo "Error: Failed to get node metrics"
        return 1
    }
    
    echo -e "\nSort pods by (memory/cpu):"
    read -p "Enter sort option: " sort_option
    
    if [ "$sort_option" = "cpu" ]; then
        echo -e "\nPod resource usage (sorted by CPU):"
        kubectl top pod --sort-by=cpu --all-namespaces || {
            echo "Error: Failed to get pod metrics"
            return 1
        }
    else
        echo -e "\nPod resource usage (sorted by memory):"
        kubectl top pod --sort-by=memory --all-namespaces || {
            echo "Error: Failed to get pod metrics"
            return 1
        }
    fi
}

# Check if option was provided as command line argument
if [ -n "$1" ]; then
    option=$1
else
    echo "Select an option:"
    echo "get_current_cluster) Show current cluster info"
    echo "set_namespace) Set namespace"
    echo "find_pods_on_node) Get pods by node name"
    echo "find_node_for_pod) Get node by pod name" 
    echo "run_netshoot_container) Run netshoot"
    echo "get_error_events) Show error events"
    echo "get_resources) Show resource usage"
    read -p "Enter function name: " option
fi

case $option in
    get_current_cluster)
        get_current_cluster
        ;;
    set_namespace)
        set_namespace
        ;;
    find_pods_on_node)
        find_pods_on_node
        ;;
    find_node_for_pod)
        find_node_for_pod
        ;;
    run_netshoot_container)
        run_netshoot_container
        ;;
    get_error_events)
        get_error_events
        ;;
    get_resources)
        get_resources
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac
