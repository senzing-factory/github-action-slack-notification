package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/pkg/errors"
	"github.com/senzing-factory/github-action-slack-notification/configuration"
)

type Message struct {
	Username    string       `json:"username,omitempty"`
	IconURL     string       `json:"icon_url,omitempty"`
	IconEmoji   string       `json:"icon_emoji,omitempty"`
	Channel     string       `json:"channel,omitempty"`
	Text        string       `json:"text,omitempty"`
	Attachments []Attachment `json:"attachments,omitempty"`
}

type Attachment struct {
	AuthorName    string  `json:"author_name,omitempty"`
	AuthorLink    string  `json:"author_link,omitempty"`
	AuthorIconURL string  `json:"author_icon,omitempty"`
	Color         string  `json:"color,omitempty"`
	Title         string  `json:"title,omitempty"`
	Fields        []Field `json:"fields,omitempty"`
}

type Field struct {
	Title string `json:"title,omitempty"`
	Value string `json:"value,omitempty"`
	Short bool   `json:"short,omitempty"`
}

func (message *Message) Send(webhook string) error {
	var err error

	msg, err := json.Marshal(message)
	if err != nil {
		return err
	}
	msgBytes := bytes.NewBuffer(msg)

	request, err := http.NewRequest(http.MethodPost, webhook, msgBytes)
	if err != nil {
		return err
	}
	request.Header.Set("Content-Type", "application/json")

	response, err := http.DefaultClient.Do(request)
	if err != nil {
		return err
	}

	if response.StatusCode >= 299 {
		err = fmt.Errorf(fmt.Sprintf("Exception: %s", response.Status))
	}
	fmt.Println(response.Status)

	return err
}

func main() {
	var err error
	var config *configuration.Config
	var slackMessage *Message

	// Init configuration from environment variables
	config = new(configuration.Config)
	err = config.Init()
	if err != nil {
		log.Fatalf("Exception: %v", err)
	}

	slackMessage = new(Message)
	slackMessage.Username = config.SlackUsername
	slackMessage.IconURL = config.SlackIconURL
	slackMessage.Channel = config.SlackChannel
	slackMessage.Attachments = []Attachment{
		{
			AuthorName:    config.GithubActor,
			AuthorLink:    "http://github.com/" + config.GithubActor,
			AuthorIconURL: "http://github.com/" + config.GithubActor + ".png?size=32",
			Color:         config.SlackColor,
			Title:         config.GithubEventName,
			Fields: []Field{
				{
					Title: "Ref",
					Value: config.GithubRef,
					Short: true,
				}, {
					Title: "Event",
					Value: config.GithubEventName,
					Short: true,
				},
				{
					Title: "Repo Action URL",
					Value: "https://github.com/" + config.GithubRepository + "/actions",
					Short: false,
				},
				{
					Title: config.SlackTitle,
					Value: config.SlackMessage,
					Short: false,
				},
			},
		},
	}

	err = slackMessage.Send(config.SlackWebhook)
	if err != nil {
		log.Printf("%+v", errors.Wrap(err, "Exception"))
	}
}
