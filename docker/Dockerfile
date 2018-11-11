FROM alpine:3.5


ENV KUBECTL_VERSION 1.10.0
ENV KOPS_VERSION 1.10.0
ENV HELM_VERSION 2.10.0
ENV ISTIO_VERSION 1.0.2

#install kubectl
RUN apk add --update \
    curl \
    jq \
    vim \
    tar \
    sed \
    git \
    bash \
    wget \
    bash-doc \
    bash-completion \
    util-linux pciutils usbutils coreutils binutils findutils grep \
    ca-certificates \
    openssh-client \
    && curl -s -L https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /usr/bin/kubectl \
    && chmod +x /usr/bin/kubectl

#install kops
RUN  curl -s -L https://github.com/kubernetes/kops/releases/download/${KOPS_VERSION}/kops-linux-amd64 -o /usr/bin/kops \
     && chmod +x /usr/bin/kops

#install HELM
RUN curl https://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-linux-amd64.tar.gz \
    -o /usr/bin/helm-v${HELM_VERSION}-linux-amd64.tar.gz \
    && tar xvzf /usr/bin/helm-v${HELM_VERSION}-linux-amd64.tar.gz -C /tmp/ \
    && mv /tmp/linux-amd64/helm /usr/bin \
    && chmod +x /usr/bin/helm \
    && helm init --client-only \
    && helm plugin install https://github.com/chartmuseum/helm-push \
    && helm plugin install https://github.com/databus23/helm-diff --version master \
    && helm plugin install https://github.com/adamreese/helm-env \
    && helm plugin install https://github.com/adamreese/helm-last \
    && helm plugin install https://github.com/ContainerSolutions/helm-monitor

#install python and dependencies
RUN apk add --update --no-cache python \
    && python -m ensurepip \
    && rm -r /usr/lib/python*/ensurepip \
    && pip install --upgrade pip setuptools \
    awscli kube-shell --ignore-installed \
    && rm -r /root/.cache

#install kompose
#go get only supports latest and alpine does not work well with go binaries but latest should be fine
RUN apk add git go musl-dev && GOPATH=/ go get -u github.com/kubernetes/kompose

#install istioctl

RUN curl -s -L https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istio-${ISTIO_VERSION}-linux.tar.gz | tar xzf - \
    && ln -s $(pwd)/istio-${ISTIO_VERSION}/bin/istioctl /usr/bin

ENV ISTIO_HOME /istio-${ISTIO_VERSION}

WORKDIR /project

CMD ["bash"]
