package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"
)

const notifyTimeout = 30 * time.Second

func NotifyNtfy(cfg *Config, title, body string) error {
	url := cfg.NtfyTopic
	if !strings.Contains(url, "://") {
		url = "https://ntfy.sh/" + url
	}
	req, err := http.NewRequest("POST", url, strings.NewReader(body))
	if err != nil {
		return fmt.Errorf("ntfy: request: %w", err)
	}
	req.Header.Set("Title", title)
	client := &http.Client{Timeout: notifyTimeout}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("ntfy: post: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 300 {
		return fmt.Errorf("ntfy: status %s", resp.Status)
	}
	return nil
}

const discordChunkChars = 1900

func NotifyDiscord(cfg *Config, text string) error {
	for len(text) > 0 {
		chunk := text
		if len(chunk) > discordChunkChars {
			cut := strings.LastIndex(chunk[:discordChunkChars], "\n")
			if cut < discordChunkChars/2 {
				cut = discordChunkChars
			}
			chunk = chunk[:cut]
		}
		text = strings.TrimPrefix(text[len(chunk):], "\n")
		payload, err := json.Marshal(map[string]string{"content": chunk})
		if err != nil {
			return fmt.Errorf("discord: marshal: %w", err)
		}
		client := &http.Client{Timeout: notifyTimeout}
		resp, err := client.Post(cfg.DiscordWebhook, "application/json", bytes.NewReader(payload))
		if err != nil {
			return fmt.Errorf("discord: post: %w", err)
		}
		resp.Body.Close()
		if resp.StatusCode >= 300 {
			return fmt.Errorf("discord: status %s", resp.Status)
		}
	}
	return nil
}
