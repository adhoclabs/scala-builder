# scala-builder

Dockerfile for creating builder container for scala applications. Contains SBT, AWS CLI and Docker.

Container is automatically published on [docker hub](https://hub.docker.com/r/ahlops/scala-builder)

### Usage

```docker pull ahlops/scala-builder```

### Build latest on Docker Hub

- Push to master, `latest` will automatically build

### Build specific version on Docker Hub

- Tag branch with name like `^/[0-9.]+$/` (ex: `git tag -a 1.0.1 -m "version 1.0.1"`)
- Push tags `git push --tags`
