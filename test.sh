
#sed -i 's/\(-k","\).*\("]$\)/\1'aaaaaa'\2/' bx-kube-replicat.yaml
OS_VERSION="LINUX"
if [[ $OS_VERSION -eq "MAC" ]];then
        sh <(curl -fsSL https://clis.ng.bluemix.net/install/osx)
    elif [[ $OS_VERSION -eq "LINUX" ]];then
        sh <(curl -fsSL https://clis.ng.bluemix.net/install/linux)
    else
        exit 1
    fi
