package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"time"
)

const protocolVersion = "2025-06-18"

var (
	apiKey    = os.Getenv("LLAMA_API_KEY")
	llamaURL  = envOr("LLAMA_URL", "http://127.0.0.1:8080")
	listen    = envOr("MCP_ADDR", "0.0.0.0:8081")
	modelName = envOr("LLAMA_MODEL", "local")
	upstream  = &http.Client{Timeout: 20 * time.Minute}
)

func envOr(k, d string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return d
}

type rpcReq struct {
	JSONRPC string          `json:"jsonrpc"`
	ID      json.RawMessage `json:"id"`
	Method  string          `json:"method"`
	Params  json.RawMessage `json:"params"`
}

type rpcErr struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
}

type rpcResp struct {
	JSONRPC string          `json:"jsonrpc"`
	ID      json.RawMessage `json:"id,omitempty"`
	Result  interface{}     `json:"result,omitempty"`
	Error   *rpcErr         `json:"error,omitempty"`
}

var delegateTool = map[string]interface{}{
	"name":        "delegate",
	"description": "Offload bulk, low-stakes text work to a free, private, always-on local model (Qwen3.6-35B-A3B on the atlas home server) so you don't spend your own context. IDEAL FOR: summarizing or extracting the relevant parts of large logs/files/diffs, first-pass triage of errors, drafting commit messages, classifying or reformatting text. The local model has a 256K-token context, so 'content' can be very large. NOT FOR: high-stakes reasoning, architecture decisions, or code that must be exactly right — do those yourself. Returns the model's text response.",
	"inputSchema": map[string]interface{}{
		"type": "object",
		"properties": map[string]interface{}{
			"task":       map[string]interface{}{"type": "string", "description": "The instruction: what to do with the content (e.g. 'summarize the errors', 'extract the function that handles auth')."},
			"content":    map[string]interface{}{"type": "string", "description": "The large text/logs/code/diff to process. Sent to the local model so it doesn't consume your context."},
			"max_tokens": map[string]interface{}{"type": "integer", "description": "Max tokens to generate (default 1024)."},
			"think":      map[string]interface{}{"type": "boolean", "description": "Enable the model's reasoning mode for harder tasks (slower). Default false — bulk delegate work runs faster with thinking off."},
		},
		"required": []interface{}{"task"},
	},
}

func main() {
	if apiKey == "" {
		log.Fatal("LLAMA_API_KEY not set")
	}
	http.HandleFunc("/", handle)
	srv := &http.Server{Addr: listen, ReadHeaderTimeout: 15 * time.Second}
	log.Printf("mcp-bridge on %s -> %s", listen, llamaURL)
	log.Fatal(srv.ListenAndServe())
}

func handle(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}
	if r.Header.Get("Authorization") != "Bearer "+apiKey {
		w.Header().Set("WWW-Authenticate", "Bearer")
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "read error", http.StatusBadRequest)
		return
	}
	var req rpcReq
	if err := json.Unmarshal(body, &req); err != nil {
		writeResp(w, "", rpcResp{JSONRPC: "2.0", Error: &rpcErr{Code: -32700, Message: "parse error"}})
		return
	}
	if strings.HasPrefix(req.Method, "notifications/") {
		w.WriteHeader(http.StatusAccepted)
		return
	}
	result, rerr := dispatch(req)
	resp := rpcResp{JSONRPC: "2.0", ID: req.ID}
	if rerr != nil {
		resp.Error = rerr
	} else {
		resp.Result = result
	}
	writeResp(w, req.Method, resp)
}

func dispatch(req rpcReq) (interface{}, *rpcErr) {
	switch req.Method {
	case "initialize":
		var p struct {
			ProtocolVersion string `json:"protocolVersion"`
		}
		json.Unmarshal(req.Params, &p)
		pv := p.ProtocolVersion
		if pv == "" {
			pv = protocolVersion
		}
		return map[string]interface{}{
			"protocolVersion": pv,
			"capabilities":    map[string]interface{}{"tools": map[string]interface{}{}},
			"serverInfo":      map[string]interface{}{"name": "atlas-local-llm", "version": "0.1.0"},
		}, nil
	case "ping":
		return map[string]interface{}{}, nil
	case "tools/list":
		return map[string]interface{}{"tools": []interface{}{delegateTool}}, nil
	case "tools/call":
		return callTool(req.Params)
	default:
		return nil, &rpcErr{Code: -32601, Message: "method not found: " + req.Method}
	}
}

func callTool(params json.RawMessage) (interface{}, *rpcErr) {
	var p struct {
		Name      string `json:"name"`
		Arguments struct {
			Task      string `json:"task"`
			Content   string `json:"content"`
			MaxTokens int    `json:"max_tokens"`
			Think     bool   `json:"think"`
		} `json:"arguments"`
	}
	if err := json.Unmarshal(params, &p); err != nil {
		return nil, &rpcErr{Code: -32602, Message: "invalid params"}
	}
	if p.Name != "delegate" {
		return toolResult("unknown tool: "+p.Name, true), nil
	}
	if strings.TrimSpace(p.Arguments.Task) == "" {
		return toolResult("'task' is required", true), nil
	}
	maxTokens := p.Arguments.MaxTokens
	if maxTokens <= 0 {
		maxTokens = 1024
	}
	text, err := runLocal(p.Arguments.Task, p.Arguments.Content, maxTokens, p.Arguments.Think)
	if err != nil {
		return toolResult("delegate error: "+err.Error(), true), nil
	}
	return toolResult(text, false), nil
}

func toolResult(text string, isErr bool) interface{} {
	return map[string]interface{}{
		"content": []interface{}{map[string]interface{}{"type": "text", "text": text}},
		"isError": isErr,
	}
}

func runLocal(task, content string, maxTokens int, think bool) (string, error) {
	user := task
	if strings.TrimSpace(content) != "" {
		user = task + "\n\n--- content ---\n" + content
	}
	payload := map[string]interface{}{
		"model": modelName,
		"messages": []interface{}{
			map[string]interface{}{"role": "system", "content": "You are a fast local assistant used to offload bulk text processing. Be concise, factual, and do exactly what is asked."},
			map[string]interface{}{"role": "user", "content": user},
		},
		"max_tokens": maxTokens,
		"stream":     false,
	}
	if !think {
		payload["chat_template_kwargs"] = map[string]interface{}{"enable_thinking": false}
	}
	b, _ := json.Marshal(payload)
	httpReq, err := http.NewRequest("POST", llamaURL+"/v1/chat/completions", bytes.NewReader(b))
	if err != nil {
		return "", err
	}
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Authorization", "Bearer "+apiKey)
	resp, err := upstream.Do(httpReq)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	rb, _ := io.ReadAll(resp.Body)
	if resp.StatusCode != 200 {
		return "", fmt.Errorf("llama-server %d: %s", resp.StatusCode, truncate(string(rb), 300))
	}
	var out struct {
		Choices []struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
	}
	if err := json.Unmarshal(rb, &out); err != nil {
		return "", fmt.Errorf("bad response: %v", err)
	}
	if len(out.Choices) == 0 {
		return "", fmt.Errorf("no choices returned")
	}
	return out.Choices[0].Message.Content, nil
}

func writeResp(w http.ResponseWriter, method string, resp rpcResp) {
	if method == "initialize" {
		w.Header().Set("Mcp-Session-Id", "atlas-mcp")
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

func truncate(s string, n int) string {
	if len(s) > n {
		return s[:n]
	}
	return s
}
