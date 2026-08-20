package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

const llmTimeout = 5 * time.Minute

type llmRequest struct {
	Messages    []llmMessage `json:"messages"`
	Temperature float64      `json:"temperature"`
	MaxTokens   int          `json:"max_tokens"`
}

type llmMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type llmResponse struct {
	Choices []struct {
		Message llmMessage `json:"message"`
	} `json:"choices"`
	Error *struct {
		Message string `json:"message"`
	} `json:"error"`
}

func LLMChat(cfg *Config, system, user string, temperature float64, maxTokens int) (string, error) {
	body, err := json.Marshal(llmRequest{
		Messages:    []llmMessage{{Role: "system", Content: system}, {Role: "user", Content: user}},
		Temperature: temperature,
		MaxTokens:   maxTokens,
	})
	if err != nil {
		return "", fmt.Errorf("llm: marshal: %w", err)
	}
	req, err := http.NewRequest("POST", cfg.LLMURL+"/v1/chat/completions", bytes.NewReader(body))
	if err != nil {
		return "", fmt.Errorf("llm: request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	if cfg.LLMKey != "" {
		req.Header.Set("Authorization", "Bearer "+cfg.LLMKey)
	}
	client := &http.Client{Timeout: llmTimeout}
	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("llm: post: %w", err)
	}
	defer resp.Body.Close()
	respBody, err := io.ReadAll(io.LimitReader(resp.Body, 4<<20))
	if err != nil {
		return "", fmt.Errorf("llm: read: %w", err)
	}
	var parsed llmResponse
	if err := json.Unmarshal(respBody, &parsed); err != nil {
		return "", fmt.Errorf("llm: parse response (status %s): %w", resp.Status, err)
	}
	if parsed.Error != nil {
		return "", fmt.Errorf("llm: server error: %s", parsed.Error.Message)
	}
	if len(parsed.Choices) == 0 {
		return "", fmt.Errorf("llm: empty response (status %s)", resp.Status)
	}
	return parsed.Choices[0].Message.Content, nil
}

func ExtractJSON(content string) (string, error) {
	start := bytes.IndexByte([]byte(content), '{')
	if start < 0 {
		return "", fmt.Errorf("llm: no JSON object in output")
	}
	depth := 0
	inString := false
	escaped := false
	for i := start; i < len(content); i++ {
		c := content[i]
		switch {
		case escaped:
			escaped = false
		case c == '\\' && inString:
			escaped = true
		case c == '"':
			inString = !inString
		case inString:
		case c == '{':
			depth++
		case c == '}':
			depth--
			if depth == 0 {
				return content[start : i+1], nil
			}
		}
	}
	return "", fmt.Errorf("llm: unterminated JSON object in output")
}
