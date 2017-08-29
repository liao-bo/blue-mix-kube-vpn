CONTAINER_CLUSTER="my_cluster"
VPN_PORT="30001"
VPN_PW="123456"

#!/bin/bash
command_exists() {
	command -v "$@" > /dev/null 2>&1
}

#check OS whether MAC or LINUX
if sw_vers|grep Mac 2>&1 >/dev/null;then
    OS_VERSION="MAC"
elif cat /proc/version|grep 'Linux' 2>&1 >/dev/null;then
    OS_VERSION="LINUX"
else 
    echo "Can't varify the OS version,the script only support MAC or LINUX"
    exit 1
fi
 
#check whether install bluemix CLI
if ! command_exists bx;then
    if [ $OS_VERSION -eq "MAC" ];then
        sh <(curl -fsSL https://clis.ng.bluemix.net/install/osx)
    elif [ $OS_VERSION -eq "LINUX" ];then
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
    if [ $OS_VERSION -eq "MAC" ];then
        curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.5.6/bin/darwin/amd64/kubectl
    elif [ $OS_VERSION -eq "LINUX" ];then
        curl -LO http://storage.googleapis.com/kubernetes-release/release/v1.5.6/bin/linux/amd64/kubectl
    else
        exit 1
    fi
    chmod +x ./kubectl && sudo mv ./kubectl /usr/local/bin/kubectl
fi


bx login -a api.ng.bluemix.net
bx cs init --host https://us-south.containers.bluemix.net
bx cs cluster-create --name $CONTAINER_CLUSTER
sleep 20
echo "waiting create container cluster "
for((i=1;i<100;i++));do
    if bx cs workers $CONTAINER_CLUSTER|grep Ready;then
        CLUSTER_IP=`bx cs workers mycluster|grep Ready|head -n 1|awk '{print $2}'`
    else
        echo"....waiting"
    fi
done
    
bx cs cluster-config my_cluster >kube_env.txt
sh ./kube_env.txt

#deployment kubenetes vpn replicat
sed 
kubectl apply -f bx-kube-replicat.yaml

kubectl apply -f bx-kube-service.yaml

nc -vz $CLUSTER_IP $VPN_PORT >/dev/null 2>&1
if [ $? -eq 1 ]; then
	echo "VPN deployment failed"
else 
        echo "VPN deployment successed"
        echo "VPN ip address is $CONTAINER_IP"
        echo "VPN port is $VPN_PORT"
        echo "VPN password is $VPN_PW"
	fi
fi
