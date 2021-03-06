FROM ubuntu:18.04

# To indicate all apt installs are not interactive
# https://unix.stackexchange.com/questions/313665/debconf-error-messages-from-apt-get-install-line-in-dockerfile
ARG DEBIAN_FRONTEND=noninteractive

# CUDA+CUDNN steps taken from https://gitlab.com/nvidia/container-images/cuda/-/blob/master/dist/ubuntu18.04/10.1

# Install base dependencies and update apt-get sources
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential curl wget zsh vim emacs unzip git gnupg2 ca-certificates locales command-not-found tree python python3 python3-pip python3-venv cmake python3-dev && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub | apt-key add - && \
    echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/cuda.list && \
    echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list

ENV CUDA_VERSION 10.2.89
ENV CUDA_PKG_VERSION 10-2=$CUDA_VERSION-1
ENV NCCL_VERSION 2.7.8
ENV CUDNN_7_VERSION 7.6.5.32
ENV CUDNN_8_VERSION 8.0.2.39

# For libraries in the cuda-compat-* package: https://docs.nvidia.com/cuda/eula/index.html#attachment-a
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        # Base CUDA
        cuda-cudart-$CUDA_PKG_VERSION \
        cuda-compat-10-2 \
        # Runtime
        cuda-libraries-$CUDA_PKG_VERSION \
        cuda-npp-$CUDA_PKG_VERSION \
        cuda-nvtx-$CUDA_PKG_VERSION \
        libcublas10=10.2.2.89-1 \
        libnccl2=$NCCL_VERSION-1+cuda10.2 \
        # Devel
        cuda-nvml-dev-$CUDA_PKG_VERSION \
        cuda-command-line-tools-$CUDA_PKG_VERSION \
        cuda-nvprof-$CUDA_PKG_VERSION \
        cuda-npp-dev-$CUDA_PKG_VERSION \
        cuda-libraries-dev-$CUDA_PKG_VERSION \
        cuda-minimal-build-$CUDA_PKG_VERSION \
        libcublas-dev=10.2.2.89-1 \
        libnccl-dev=2.7.8-1+cuda10.2 \
        # CUDNN 
        libcudnn7=$CUDNN_7_VERSION-1+cuda10.2 \
        libcudnn7-dev=$CUDNN_7_VERSION-1+cuda10.2 \
        libcudnn8=$CUDNN_8_VERSION-1+cuda10.2 \
        libcudnn8-dev=$CUDNN_8_VERSION-1+cuda10.2 && \
    apt-mark hold libnccl2 libcudnn7 libcudnn8 libnccl-dev && \
    ln -s cuda-10.2 /usr/local/cuda

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64
ENV LIBRARY_PATH /usr/local/cuda/lib64/stubs

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_REQUIRE_CUDA "cuda>=10.2 brand=tesla,driver>=396,driver<397 brand=tesla,driver>=410,driver<411 brand=tesla,driver>=418,driver<419 brand=tesla,driver>=440,driver<441"

ENV NODE_VERSION 14

# Node 12
RUN curl -sL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash - && \
    apt-get install -y --no-install-recommends nodejs

# GO
ENV GOLANG_VERSION 1.15.2
RUN curl -sL "https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz" | tar xzf - -C /usr/local 
ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

# AWS CLI
RUN apt-get install -y --no-install-recommends unzip && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install

# Set default language 
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen

# SSH access
# https://docs.docker.com/engine/examples/running_ssh_service/
# An SSH server is not a best practice but we do this so we can get remote SSH access
# to the container for tools like VS Code. It's sometimes nice to use the Remote-SSH
# extension to gain access to a box. But then you'd like to then make use of the Remote-Container
# extension. But this layer of embedding isn't supported yet.
# https://github.com/microsoft/vscode-remote-release/issues/20
# https://github.com/microsoft/vscode-remote-release/issues/2994
RUN apt-get update && \
    apt-get install -y --no-install-recommends openssh-server && \
    mkdir /var/run/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# Anaconda
RUN wget --quiet https://repo.anaconda.com/archive/Anaconda3-2020.02-Linux-x86_64.sh -O conda.sh && \
    /usr/bin/zsh conda.sh -b -p /opt/conda && \
    rm conda.sh

# Create a user in the container to represent the local user running the container. And then run the remaining commands
# as this user.

# Add a user/group 1000:1000 (which most likely maps to the local user) so that home, etc... will work
ARG USERNAME=dev
ARG UID=1000
ARG GID=$UID
RUN groupadd --gid ${GID} ${USERNAME} && \
    useradd --uid ${UID} --gid ${USERNAME} --shell /usr/bin/zsh --create-home ${USERNAME} && \
    #
    # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
    apt-get update && \
    apt-get install -y --no-install-recommends sudo && \
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

# Switch to the default user to setup vim/zsh/etc... extensions
USER ${USERNAME}

# Vim Extensions
RUN git clone https://github.com/kurtb/dotvim.git ~/.vim && \
    cd ~/.vim && \
    git submodule update --init --recursive && \
    cd .. && \
    ln -s $(pwd)/.vim/.vimrc .vimrc && \
    cd ~/.vim/bundle/YouCompleteMe && \
    python3 install.py --all 

# Zsh
RUN git clone https://github.com/kurtb/dotzsh.git ~/dotzsh && \
    cd ~/dotzsh && \
    git submodule update --init --recursive && \
    bash ./install.sh && \
    cd .. && \
    ln -s -f $(pwd)/dotzsh/.zshrc ~/.zshrc

# Init Anaconda (done following zsh init)
RUN /opt/conda/bin/conda init zsh && \
    /opt/conda/bin/conda config --set auto_activate_base false

# Create the .ssh directory so that it exists as the default user
RUN mkdir /home/${USERNAME}/.ssh

WORKDIR /home/${USERNAME}

# Switch back to root for launching the SSH server
USER root

# Latest postgres 
RUN echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    curl -fsSL  https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    apt-get update && \
    apt-get install -y --no-install-recommends postgresql-client libpq-dev

# Delete all the SSH host keys and then copy the startup script. The script will regenerate these
# keys on first boot. By then mounting the volume we can preserve them across dev container
# instances.
RUN rm /etc/ssh/ssh_host_*
COPY startup.sh /root/startup.sh

# Volumes for the home directory as well as root SSL certs so we can preserve both
# across runs or upgrades
VOLUME ["/home/${USERNAME}", "/etc/ssh/"]

EXPOSE 22
CMD ["/root/startup.sh"]
