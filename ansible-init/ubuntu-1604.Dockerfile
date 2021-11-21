FROM ubuntu:16.04 AS base

ENV DEBIAN_FRONTEND noninteractive

# Install dependencies.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       apt-utils \
       build-essential \
       locales \
       libffi-dev \
       libssl-dev \
       libyaml-dev \
       python3-dev \
       python3-pip \
       python3-yaml \
       software-properties-common \
       rsyslog systemd systemd-cron sudo iproute2 \
       openssh-server \
       vim \
       net-tools \
       ansible \
    && rm -Rf /var/lib/apt/lists/* \
    && rm -Rf /usr/share/doc && rm -Rf /usr/share/man \
    && apt-get clean
RUN sed -i 's/^\($ModLoad imklog\)/#\1/' /etc/rsyslog.conf


FROM base AS additional_pkgs

# Upgrade pip to latest version.
# RUN pip3 install --upgrade pip
                           
# Install Ansible via Pip.
# RUN pip3 install ansible

# Fix potential UTF-8 errors with ansible-test.
RUN locale-gen en_US.UTF-8

FROM additional_pkgs AS config_files
# copy ssh_keys
COPY ssh_keys/playground /root/.ssh/id_rsa
COPY ssh_keys/playground.pub /root/.ssh/id_rsa.pub
COPY ssh_keys/playground.pub /root/.ssh/authorized_keys
COPY ssh_keys/playground.pub /root/.ssh/known_hosts
COPY ssh_keys/playground /etc/ssh/ssh_host_rsa_key
COPY ssh_keys/playground.pub /etc/ssh/ssh_host_rsa_key.pub


FROM config_files AS services
EXPOSE 22
VOLUME ["/sys/fs/cgroup", "/tmp", "/run/sshd"]
RUN sed -i '/^#Port\ 22/s/^#//' /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin.*/PermitRootLogin\ yes/' /etc/ssh/sshd_config && \
    echo "root:root" | chpasswd && \
    sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_rsa_key/HostKey \/etc\/ssh\/ssh_host_rsa_key/g' /etc/ssh/sshd_config
    

WORKDIR /root/playground
ENV PATH "$PATH:/root/playground/deploy"

CMD ["/usr/sbin/sshd", "-D"]