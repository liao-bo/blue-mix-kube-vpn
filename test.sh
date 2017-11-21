
#sed -i 's/\(-k","\).*\("]$\)/\1'aaaaaa'\2/' bx-kube-replicat.yaml
OS_VERSION="1111"
if [[ $OS_VERSION -eq "MAC" ]];then
        #sh <(curl -fsSL https://clis.ng.bluemix.net/install/osx)
        echo "111"
    elif [[ $OS_VERSION -eq "LINUX" ]];then
        #sh <(curl -fsSL https://clis.ng.bluemix.net/install/linux)
        echo "222"
    else
        exit 1
    fi
#test
