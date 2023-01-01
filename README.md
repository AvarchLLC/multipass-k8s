# multipass-k8s

Following script install Kubernetes. Multipass is used for virtualization.

Multipass is a lightweight VM manager for Linux, Windows and macOS. It's designed for developers who want a fresh Ubuntu environment with a single command. It uses KVM on Linux, Hyper-V on Windows and HyperKit on macOS to run the VM with minimal overhead. It can also use VirtualBox on Windows and macOS. Multipass will fetch images for you and keep them up to date.

First multpipass need to be installed whuch is required for virtualization to run this script

This script is tested on ubuntu 22.04.1

## execute the following script

```
wget https://raw.githubusercontent.com/Avarch-org/multipass-k8s/main/createCluster.sh && chmod +x  createCluster.sh &&  ./createCluster.sh
```

## List down vms to verify

```
multipass list
```

![system schema](https://raw.githubusercontent.com/Avarch-org/multipass-k8s/main/Screenshot%20from%202022-12-30%2022-36-00.png)

## login to master node

```
multipass shell master
```

![system schema](https://raw.githubusercontent.com/Avarch-org/multipass-k8s/main/Screenshot%20from%202022-12-30%2022-37-52.png)

## execute from master node

```
https://raw.githubusercontent.com/Avarch-org/multipass-k8s/main/Screenshot%20from%202022-12-30%2022-38-41.png
```

![system schema](https://raw.githubusercontent.com/Avarch-org/multipass-k8s/main/Screenshot%20from%202022-12-30%2022-38-41.png)
