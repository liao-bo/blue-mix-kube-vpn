#!/bin/bash
set -e

DIR=$(cd `dirname $0`; pwd)

source $DIR/config.sh

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

#check OS whether MAC or LINUX
if command_exists sw_vers;then
    OS_VERSION="MAC"
    $SED_BAK=".bak"
elif cat /proc/version|grep 'Linux' 2>&1 >/dev/null;then
    OS_VERSION="LINUX"
else 
    echo "Can't varify the OS version,the script only support MAC or LINUX"
    exit 1
fi
echo "$OS_VERSION"
#check whether install bluemix CLI
if ! command_exists bx;then
    if [[ $OS_VERSION -eq "MAC" ]];then
        sh <(curl -fsSL https://clis.ng.bluemix.net/install/osx)
    elif [[ $OS_VERSION -eq "LINUX" ]];then
        sh <(curl -fsSL https://clis.ng.bluemix.net/install/linux)
    else
        exit 1
    fi
fi

#check whether install bluemix container service CLI
if ! bx plugin list|grep "container-service";then
    bx plugin install container-service -r Bluemix
fi

#check whether install kubenetes CLI
if ! command_exists kubectl;then
    wget https://github.com/liao-bo/kubectl/archive/1.5.6.tar.gz
    tar xzvf 1.5.6.tar.gz
    KUBE_PATH='/usr/local/bin/kubectl'
    if [[ $OS_VERSION -eq "MAC" ]];then
        sudo mv ./kubectl-1.5.6/darwin-V1.5.6/kubectl $KUBE_PATH
    elif [[ $OS_VERSION -eq "LINUX" ]];then
        sudo mv ./kubectl-1.5.6/linux-V1.5.6/kubectl $KUBE_PATH
    else
        exit 1
    fi
    chmod +x $KUBE_PATH 
fi


bx login -a api.ng.bluemix.net
bx cs init --host https://us-south.containers.bluemix.net
bx target --cf
bx iam orgs
bx iam spaces
echo "cluster name is $CONTAINER_CLUSTER"
if ! bx cs clusters|grep $CONTAINER_CLUSTER 2>&1 >/dev/null;then
   bx cs cluster-create --name $CONTAINER_CLUSTER
   sleep 20
   echo "waiting create container cluster "
fi
for((i=1;i<100;i++));do
    if bx cs clusters|grep $CONTAINER_CLUSTER|grep normal;then
        CLUSTER_IP=`bx cs workers $CONTAINER_CLUSTER|grep Ready|head -n 1|awk '{print $2}'`
        break
    else
        sleep 5
        echo "....waiting"
        echo `bx cs clusters|grep $CONTAINER_CLUSTER`
    fi
done
    
bx cs cluster-config my_cluster|grep export >kube_env.txt
source ./kube_env.txt

#deployment kubenetes vpn replicat
echo "deploying kube replicat"
sed -i $SED_BAK 's/\(-k","\).*\("]$\)/\1'${VPN_PW}'\2/' $DIR/bx-kube-replicat.yaml
kubectl apply -f bx-kube-replicat.yaml

#deployment kubenetes vpn service network
echo "deploying kube service"
sed -i $SED_BAK 's/\(nodePort: \)[0-9]*$/\1'${VPN_PORT}'/' $DIR/bx-kube-service.yaml 
kubectl apply -f bx-kube-service.yaml

nc -vz $CLUSTER_IP $VPN_PORT >/dev/null 2>&1
if [ $? -eq 1 ]; then
	echo "VPN deployment failed"
else 
        echo "VPN deployment successed"
        echo "VPN ip address is $CLUSTER_IP"
        echo "VPN port is $VPN_PORT"
        echo "VPN password is $VPN_PW"
        echo "VPN encryption type defautl is aes-256-cfb"
fi
