FROM amazon/aws-cli

ARG KUBESCAPE_VERSION

RUN curl -sL -o /usr/bin/kubescape \
    https://github.com/armosec/kubescape/releases/download/${KUBESCAPE_VERSION}/kubescape-ubuntu-latest

RUN chmod +x /usr/bin/kubescape

ENTRYPOINT [ "kubescape" ]
