# -----------------------------------------------------------------------------
# Stage: BUILD
# -----------------------------------------------------------------------------
FROM golang:1.13.11-alpine3.10 as BUILD

ARG GITHUB_HEAD_REF="master"
ARG GITHUB_EVENT_NAME="push"

# Add github
RUN apk update && \
  apk upgrade && \
  apk add --no-cache \
  git \
  make

WORKDIR /go/src

RUN git clone https://github.com/senzing-factory/github-action-slack-notification.git

# Checkout to target branch and if not master, then locally test
# merging master into branch.
WORKDIR /go/src/github-action-slack-notification
RUN git checkout ${GITHUB_HEAD_REF}; \
  if [[ "${GITHUB_HEAD_REF}" != "master" && ${GITHUB_EVENT_NAME} == "pull_request" ]]; then \
  git merge master; \
  fi

# Building go app
RUN make build

# -----------------------------------------------------------------------------
# Stage: BUILD
# -----------------------------------------------------------------------------
FROM alpine:3.21

LABEL "com.github.actions.icon"="message-square"
LABEL "com.github.actions.color"="purple"
LABEL "com.github.actions.name"="GitHub Aciton Slack Notification"
LABEL "com.github.actions.description"="Send notification to Slack"

COPY --from=BUILD /go/bin/github-action-slack-notification /usr/bin
COPY --from=BUILD /go/src/github-action-slack-notification/LICENSE /
COPY --from=BUILD /go/src/github-action-slack-notification/README.md /

HEALTHCHECK CMD git --version || exit 1

USER 1001

ENTRYPOINT ["github-action-slack-notification"]
