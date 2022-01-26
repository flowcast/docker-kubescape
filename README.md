# flowcast-kubescape

Runs kubescape against the flowcast k8s prod cluster

## Prerequisites

- make
- aws-cli
- docker

## Essential Make Targets

These are the bare minimum targets you need to run kubescape

### Building

Build the docker images

```
make build
```

### Update Kubeconfig

Pulls the kubeconfig from aws

```
make kubeconfig
```

### Run Kubescape

Runs kubescape against the configured cluster

```
make scan
```

## Other Make Targets

Various other make targets

### Run Locally

This will use whatever context you have kubectl set to.

```
make install
make local
```

### Bash in Docker

```
make bash
```

## Jenkins

This job runs in Jenkins once a day and reports errors to the
`#alerts-kubescape` slack channel.

