#!/bin/sh
echo "Please select a CNI provider"
echo -n "Enter 1 for Calico, Enter 2 for Flannel, Enter 3 for Weave " 
echo "Please choose:"
echo "1. Calico"
echo "2. Flannel"
echo "3. Weave"
read cni

echo 'Master VM is being created'

multipass launch -c 2 -m 2G -d 20G -n master

echo 'Master VM is sucessfully created'

echo 'Node1 VM is being created'

multipass launch -c 2 -m 2G -d 20G -n node1

echo 'Node1 VM is sucessfully created'

echo 'Node2 VM is being created'

multipass launch -c 2 -m 2G -d 20G -n node2

echo 'Node2 VM is sucessfully created'

masterIP=`multipass exec master -- hostname -I`
node1IP=`multipass exec node1 -- hostname -I`
node2IP=`multipass exec node2 -- hostname -I`
echo $masterIP
echo $node1IP
echo $node2IP

for Item in master node1 node2
do
    echo "${Item}"
    multipass exec ${Item} -- bash <<EOF
    sudo hostnamectl set-hostname "${Item}.k.net"
    echo "${masterIP}  master.k.net    master" | sudo tee -a /etc/hosts
    echo "${node1IP}  node1.k.net    node1" | sudo tee -a /etc/hosts
    echo "${node2IP}  node2.k.net    node2" | sudo tee -a /etc/hosts
    sudo swapoff -a
    sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
    sudo tee /etc/modules-load.d/containerd.conf <<INTERNAL
    overlay
    br_netfilter
INTERNAL
    sudo modprobe overlay
    sudo modprobe br_netfilter
    sudo tee /etc/sysctl.d/kubernetes.conf <<INTERNAL1
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    net.ipv4.ip_forward = 1
INTERNAL1
    sudo sysctl --system
    sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt update
    sudo apt install -y containerd.io
    containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
    sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
    sudo systemctl restart containerd
    sudo systemctl enable containerd
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
    sudo apt update
    sudo apt install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl
   
EOF
done



 multipass exec master -- bash <<EOF
    sudo kubeadm init --control-plane-endpoint=master.k.net --pod-network-cidr=10.244.0.0/16
    mkdir -p /home/ubuntu/.kube
    sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
    sudo chown $(id -u):$(id -g) /home/ubuntu/.kube/config
EOF

addNodeCmd=`multipass exec master -- kubeadm token create --print-join-command`
echo $addNodeCmd

 multipass exec node1 -- bash <<EOF
   sudo $addNodeCmd
EOF

 multipass exec node2 -- bash <<EOF
    sudo $addNodeCmd
EOF

 multipass exec master -- bash <<EOF
    
    if [ $cni = "1" ]; then
    kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml
    elif [ $cni = "2" ]; then
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
    else
    kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
    fi

EOF

multipass exec master -- bash <<EOF
    kubectl label node node1.k.net node-role.kubernetes.io/worker=worker
    kubectl label node node2.k.net node-role.kubernetes.io/worker=worker
EOF