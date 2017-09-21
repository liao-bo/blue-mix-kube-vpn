
sed -i '' 's/\(-k","\).*\("]$\)/\1'${VPN_PW}'\2/' $DIR/bx-kube-replicat.yaml
