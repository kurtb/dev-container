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
* Emacs
* AWS CLI

## Dev container
When running, and especially when volume mounting files, the dev container expects to be run as the user who invoked
the container using the following command. This avoids mounted files having root level permissioning.

`docker run --rm --gpus all -it -u $(id -u):$(id -g) dev-container`

But just switching the user ID causes issues around home directories, etc...

https://medium.com/redbubble/running-a-docker-container-as-a-non-root-user-7d2e00f8ee15
https://medium.com/faun/set-current-host-user-for-docker-container-4e521cef9ffc

## Passing in AWS Credentials

https://ryanparman.com/posts/2019/running-aws-vault-with-local-docker-containers/

For instance if you have a profile named eng the below will work

docker run --rm --gpus all --env-file <(aws-vault exec eng -- env | grep --color=never ^AWS_) -it -u $(id -u):$(id -g) dev-container

## SSH keys

You can mount your authorized_keys into the container to make ssh'ing into it easy

From a remote box to the host you can do
`ssh-copy-id user@host`

Or if local
`cat <your_public_key_file> >> ~/.ssh/authorized_keys`

## Running
`docker run --rm --gpus all -d -v $(pwd):/workspace -v /home/kurtb/.ssh/authorized_keys:/home/dev/.ssh/authorized_keys -p 8022:22 dev-container`

You can then connect to it from VS Code, etc...

To get a shell simply launch with /usr/bin/zsh, or with SSH and a shell, service restart sshd && /user/bin/zsh

`docker run --rm -it --gpus all -v $(pwd):/workspace -v /home/kurtb/.ssh/authorized_keys:/home/dev/.ssh/authorized_keys -p 8022:22 -u dev dev-container zsh`

`docker run --rm -it --gpus all -v $(pwd):/workspace -v /home/kurtb/.ssh/authorized_keys:/home/dev/.ssh/authorized_keys -p 8022:22 -u dev dev-container sh -c "sudo service ssh restart && zsh" `