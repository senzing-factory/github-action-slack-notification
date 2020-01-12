# -----------------------------------------------------------------------------
# Stage: BUILD
# -----------------------------------------------------------------------------
FROM golang:1.13.4-alpine3.10 as BUILD

ARG BRANCH="master"

# Add github
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
        git

WORKDIR /go/src

RUN git clone https://github.com/senzing/git-action-slack-notification.git && \
    cd git-action-slack-notification && \
    git checkout ${BRANCH}

RUN go get ./... && \
    go install ./...

# -----------------------------------------------------------------------------
# Stage: BUILD
# -----------------------------------------------------------------------------
FROM alpine:3.10

LABEL "com.github.actions.icon"="message-square"
LABEL "com.github.actions.color"="purple"
LABEL "com.github.actions.name"="Git Aciton Slack Notification"
LABEL "com.github.actions.description"="Send notification to Slack"

COPY --from=BUILD /go/bin/git-action-slack-notification /usr/bin
COPY --from=BUILD /go/src/git-action-slack-notification/LICENSE /
COPY --from=BUILD /go/src/git-action-slack-notification/README.md /

ENTRYPOINT ["git-action-slack-notification"]
