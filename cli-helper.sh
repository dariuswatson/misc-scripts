#!/bin/bash
# all the cli's!
# basic script to pull a list of cli used for infra/devops
# Darius Watson 11/08/2025
#

## -------------- Global Vars -------------- ##
    working_dir="/tmp/cli-helper"
    rm -rf $working_dir
    mkdir -p $working_dir
    cd $working_dir

    # -- latest versions
    latest_clusterctl="v1.11.13"
    latest_clusterawsadm="v2.9.2"
    latest_kind="v0.30.0"

    # currently v1.31 12/21/2024
    latest_kubectl=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)

    # eks_kubectl="v1.29.0"
    eks_kubectl="$latest_kubectl"

## -------------- Functions -------------- ##

    cli_aws()
    {
        sudo apt install unzip -y
        curl -Lo $working_dir/awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        aws --version
    }

    cli_clusterctl()
    {
        curl -Lo $working_dir/clusterctl "https://github.com/kubernetes-sigs/cluster-api/releases/download/$latest_clusterctl/clusterctl-linux-amd64"
        chmod +x ./clusterctl
        sudo mv ./clusterctl /usr/local/bin/clusterctl
        clusterctl version
    }

    cli_kind()
    {
        curl -Lo $working_dir/kind "https://kind.sigs.k8s.io/dl/$latest_kind/kind-linux-amd64"
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
        kind --version
    }

    cli_kubectl()
    {
        echo "Latest kubectl version: $latest_kubectl"
        echo "Current kubectl client version: $(kubectl version --short | grep Client | awk '{ print $3 }')"
        echo "Upgrading kubectl version"
        curl -LO "https://storage.googleapis.com/kubernetes-release/release/$latest_kubectl/bin/linux/amd64/kubectl"
        chmod +x ./kubectl
        sudo mv ./kubectl /usr/local/bin/kubectl
    }

    cli_clusterawsadm()
    {
        curl -Lo $working_dir/clusterawsadm "https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases/download/$latest_clusterawsadm/clusterawsadm-linux-amd64"
        chmod +x ./clusterawsadm
        sudo mv ./clusterawsadm /usr/local/bin/clusterawsadm
        clusterawsadm version
    }

    cli_helm()
    {
        # curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
        curl -Lo $working_dir/get_helm.sh "https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3"
        chmod 700 $working_dir/get_helm.sh
        $working_dir/get_helm.sh
    }

    cli_all()
    {
        cli_aws
        cli_kubectl
        cli_kind
        cli_clusterctl
        cli_clusterawsadm
        cli_helm
        cli_flux
    }

    cli_flux()
    {
        curl -s https://fluxcd.io/install.sh | sudo bash
    }

    cli_terraform()
    {
        #wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        #echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt update && sudo apt install terraform
    }

## -------------- Main -------------- ##

echo "number of params $#"
    if [ $# -eq 0 ]; then
        echo "Need cli aws, kubectl, kind, clusterctl, clusterawsadm, helm, tf, all"
    else
        echo "first param $1"
        case $1 in
            aws )
                cli_aws
            ;;
            kubectl )
                cli_kubectl
            ;;
            kind )
                cli_kind
            ;;
            clusterctl )
                cli_clusterctl
            ;;
            clusterawsadm )
                cli_clusterawsadm
            ;;
            flux )
                cli_flux
            ;;
            helm )
                cli_helm
            ;;
            tf )
                cli_terraform
            ;;

            all )
                cli_all
            ;;
            * )
                echo "not sure"
            ;;
        esac
    fi

