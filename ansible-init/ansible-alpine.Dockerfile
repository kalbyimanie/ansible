FROM alpine:3.12.1 AS base
RUN apk --update --no-cache add python3 \
                                openssh-client \
                                openssh-server \
                                vim \
                                ansible \
                                net-tools \
                                iputils \
                                bash \
                                openrc && \
                                rm -rf /var/cache/apk/*


FROM base AS config_files
# copy ssh_keys
COPY ssh_keys/playground /root/.ssh/id_rsa
COPY ssh_keys/playground.pub /root/.ssh/id_rsa.pub
COPY ssh_keys/playground.pub /root/.ssh/authorized_keys
COPY ssh_keys/playground.pub /root/.ssh/known_hosts
COPY ssh_keys/playground /etc/ssh/ssh_host_rsa_key
COPY ssh_keys/playground.pub /etc/ssh/ssh_host_rsa_key.pub


FROM config_files AS services
# start ssh service
EXPOSE 22
VOLUME ["/sys/fs/cgroup"]
RUN mkdir -p /run/openrc && touch /run/openrc/softlevel && \
    sed -i '/^#Port\ 22/s/^#//' /etc/ssh/sshd_config && \
    sed -i s/#PermitRootLogin.*/PermitRootLogin\ yes/ /etc/ssh/sshd_config && \
    echo "root:root" | chpasswd && \
    sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_rsa_key/HostKey \/etc\/ssh\/ssh_host_rsa_key/g' /etc/ssh/sshd_config && \
    rc-update add sshd
CMD ["/usr/sbin/sshd","-D"]