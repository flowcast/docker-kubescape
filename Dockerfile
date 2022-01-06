FROM amazon/aws-cli

ARG KUBESCAPE_VERSION

ENV KUBESCAPE_SKIP_UPDATE_CHECK 1

RUN curl -sL -o /usr/bin/kubescape \
    https://github.com/armosec/kubescape/releases/download/${KUBESCAPE_VERSION}/kubescape-ubuntu-latest

RUN chmod +x /usr/bin/kubescape

ENTRYPOINT [ "kubescape" ]
