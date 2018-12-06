# dcind (Docker-Compose-in-Docker)

[![](https://images.microbadger.com/badges/image/netresearch/dcind.svg)](http://microbadger.com/images/netresearch/dcind "Get your own image badge on microbadger.com")

Use this ```Dockerfile``` to build a base image for your integration tests in [Concourse CI](http://concourse.ci/). Alternatively, you can use a ready-to-use image from the Docker Hub: [netresearch/dcind](https://hub.docker.com/r/netresearch/dcind/). The image is Alpine based.

Here is an example of a Concourse [job](http://concourse.ci/concepts.html) that uses ```netresearch/dcind``` image to run a bunch of containers in a task, and then runs the integration test suite. You can find a full version of this example in the [```example```](example) directory.

```yaml
  - name: integration
    plan:
      - aggregate:
        - get: code
          params: {depth: 1}
          passed: [unit-tests]
          trigger: true
        - get: redis
          params: {save: true}
        - get: busybox
          params: {save: true}
      - task: Run integration tests
        privileged: true
        config:
          platform: linux
          image_resource:
            type: docker-image
            source:
              repository: netresearch/dcind
          inputs:
            - name: code
            - name: redis
            - name: busybox
          run:
            path: sh
            args:
              - -exc
              - |
                source /docker-lib.sh
                start_docker

                # Strictly speaking, preloading of Docker images is not required.
                # However, you might want to do this for a couple of reasons:
                # - If the image comes from a private repository, it is much easier to let Concourse pull it,
                #   and then pass it through to the task.
                # - When the image is passed to the task, Concourse can often get the image from its cache.
                docker load -i redis/image
                docker tag "$(cat redis/image-id)" "$(cat redis/repository):$(cat redis/tag)"

                docker load -i busybox/image
                docker tag "$(cat busybox/image-id)" "$(cat busybox/repository):$(cat busybox/tag)"

                message info This is just to visually check in the log that images have been loaded successfully
                docker images

                message Run the container with tests and its dependencies.
                docker-compose -f code/example/integration.yml run tests

                message header Cleanup.
                message info Not sure if this is required. It's quite possible that Concourse is smart enough to clean up the Docker mess itself.
                docker-compose -f code/example/integration.yml down
                docker volume rm $(docker volume ls -q)


```

## Included tools

### Messages
For better organized log files, this image provides commands on the CLI for a colourful output:

```bash
message info "Short info message"

message header "Big headline with deviders"

message error 418 "Error message with exit code"

message warn "Use it when something goes wrong"

message ok "Use it for successful processes"

message code "<example>My exaple code</example>"
```
