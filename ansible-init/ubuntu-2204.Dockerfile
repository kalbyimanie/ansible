FROM ubuntu:22.04 AS base

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    locales \
    ca-certificates \
    curl \
    sudo \
    openssh-server \
    rsyslog \
    systemd \
    systemd-cron \
    iproute2 \
    net-tools \
    vim \
    python3 \
    python3-pip \
    python3-dev \
    python3-setuptools \
    python3-venv \
    libffi-dev \
    libssl-dev \
    libyaml-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
RUN sed -i 's/^\($ModLoad imklog\)/#\1/' /etc/rsyslog.conf

RUN python3 -m pip install --no-cache-dir --upgrade pip setuptools wheel

RUN python3 -m pip install --no-cache-dir \
    "ansible==2.9.27" \
    "cryptography<40" \
    "jinja2<3.1" \
    "MarkupSafe<2.1"

# ---------- SSH KEYS ----------
FROM base AS config_files

COPY ssh_keys/playground /root/.ssh/id_rsa
COPY ssh_keys/playground.pub /root/.ssh/id_rsa.pub
COPY ssh_keys/playground.pub /root/.ssh/authorized_keys
COPY ssh_keys/playground.pub /root/.ssh/known_hosts
COPY ssh_keys/playground /etc/ssh/ssh_host_rsa_key
COPY ssh_keys/playground.pub /etc/ssh/ssh_host_rsa_key.pub

# ---------- SERVICES ----------
FROM config_files AS services

EXPOSE 22
VOLUME ["/sys/fs/cgroup", "/tmp", "/run/sshd"]

RUN sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    echo "root:root" | chpasswd && \
    sed -i 's|#HostKey /etc/ssh/ssh_host_rsa_key|HostKey /etc/ssh/ssh_host_rsa_key|' /etc/ssh/sshd_config

WORKDIR /root/playground
ENV PATH="$PATH:/root/playground/deploy"

CMD ["/usr/sbin/sshd", "-D"]
