# -----------------------------------------------------------------------------
# Stage: BUILD
# -----------------------------------------------------------------------------
FROM golang:1.13.4-alpine3.10 as BUILD

ARG GITHUB_HEAD_REF="master"
ARG GITHUB_EVENT_NAME="push"

# Add github
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
        git \
        make

WORKDIR /go/src

RUN git clone https://github.com/senzing/git-action-slack-notification.git

# Checkout to target branch and if not master, then locally test
# merging master into branch.
WORKDIR /go/src/git-action-slack-notification
RUN git checkout ${GITHUB_HEAD_REF}; \
    if [[ "${GITHUB_HEAD_REF}" != "master" && ${GITHUB_EVENT_NAME} == "pull_request" ]]; then \
        git merge master; \
    fi

# Building go app
RUN make build

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
