# Dev container

Dockerfile with standard toolchains I find useful during development.

These include...
* CUDA 10.1
* CUDNN 7.6
* Node 12
* Go 1.14
* Python 3
* Anaconda
* Vim + Oh My Zsh + Extensions
* AWS CLI

## Dev container
When running, and especially when volume mounting files, the dev container expects to be run as the user who invoked
the container using the following command. This avoids mounted files having root level permissioning.

`docker run --rm --gpus all -it -u $(id -u):$(id -g) dev-container`

But just switching the user ID causes issues around home directories, etc...

https://medium.com/redbubble/running-a-docker-container-as-a-non-root-user-7d2e00f8ee15
https://medium.com/faun/set-current-host-user-for-docker-container-4e521cef9ffc


