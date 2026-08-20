package main

import (
	"bytes"
	"encoding/base64"
	"fmt"
	"io"
	"mime"
	"mime/multipart"
	"mime/quotedprintable"
	"net/mail"
	"regexp"
	"strings"
	"time"

	"github.com/emersion/go-imap/v2"
	"github.com/emersion/go-imap/v2/imapclient"
)

const (
	imapAddr          = "imap.gmail.com:993"
	imapMailbox       = "[Gmail]/All Mail"
	imapSeedWindow    = 7 * 24 * time.Hour
	imapMaxPerSync    = 500
	imapTextBytes     = 64 << 10
	imapMaxMIMEParts  = 20
	imapBodyKeepChars = 8000
)

func SyncMail(store *Store, cfg *Config, now time.Time) (int, error) {
	client, err := imapclient.DialTLS(imapAddr, nil)
	if err != nil {
		return 0, fmt.Errorf("imap: dial: %w", err)
	}
	defer client.Close()
	if err := client.Login(cfg.IMAPUser, cfg.IMAPPassword).Wait(); err != nil {
		return 0, fmt.Errorf("imap: login: %w", err)
	}
	selected, err := client.Select(imapMailbox, &imap.SelectOptions{ReadOnly: true}).Wait()
	if err != nil {
		return 0, fmt.Errorf("imap: select: %w", err)
	}
	if store.Sync.UIDValidity != selected.UIDValidity {
		store.Sync.UIDValidity = selected.UIDValidity
		store.Sync.LastUID = 0
	}

	var uids imap.UIDSet
	if store.Sync.LastUID == 0 {
		found, err := client.UIDSearch(&imap.SearchCriteria{Since: now.Add(-imapSeedWindow)}, nil).Wait()
		if err != nil {
			return 0, fmt.Errorf("imap: seed search: %w", err)
		}
		all := found.AllUIDs()
		if len(all) > imapMaxPerSync {
			all = all[len(all)-imapMaxPerSync:]
		}
		if len(all) == 0 {
			store.Sync.MailFetched = now
			return 0, client.Logout().Wait()
		}
		uids = imap.UIDSetNum(all...)
	} else {
		uids = imap.UIDSet{}
		uids.AddRange(imap.UID(store.Sync.LastUID+1), 0)
	}

	headerSection := &imap.FetchItemBodySection{Specifier: imap.PartSpecifierHeader, Peek: true}
	textSection := &imap.FetchItemBodySection{
		Specifier: imap.PartSpecifierText, Peek: true,
		Partial: &imap.SectionPartial{Offset: 0, Size: imapTextBytes},
	}
	fetch := client.Fetch(uids, &imap.FetchOptions{
		UID:         true,
		BodySection: []*imap.FetchItemBodySection{headerSection, textSection},
	})

	index := store.ThreadByMsgID()
	added := 0
	maxUID := store.Sync.LastUID
	for added < imapMaxPerSync {
		raw := fetch.Next()
		if raw == nil {
			break
		}
		buf, err := raw.Collect()
		if err != nil {
			fetch.Close()
			return added, fmt.Errorf("imap: fetch collect: %w", err)
		}
		if uint32(buf.UID) > maxUID {
			maxUID = uint32(buf.UID)
		}
		if uint32(buf.UID) <= store.Sync.LastUID && store.Sync.LastUID != 0 {
			continue
		}
		msg, refs := parseRawMessage(buf.FindBodySection(headerSection), buf.FindBodySection(textSection), cfg.MyEmail)
		if msg == nil {
			continue
		}
		if _, seen := index[msg.MsgID]; seen {
			continue
		}
		if err := store.SaveMessage(msg); err != nil {
			fetch.Close()
			return added, err
		}
		applyMessage(store, index, msg, refs, cfg.MyEmail)
		added++
	}
	if err := fetch.Close(); err != nil {
		return added, fmt.Errorf("imap: fetch: %w", err)
	}
	store.Sync.LastUID = maxUID
	store.Sync.MailFetched = now
	return added, client.Logout().Wait()
}

func applyMessage(store *Store, index map[string]*Thread, msg *Message, refs []string, myEmail string) {
	var thread *Thread
	for _, ref := range refs {
		if t, ok := index[ref]; ok {
			thread = t
			break
		}
	}
	if thread == nil {
		thread = &Thread{ID: msg.MsgID, State: ThreadNew, Subject: msg.Subject}
		store.Threads = append(store.Threads, thread)
	}
	thread.MsgIDs = append(thread.MsgIDs, msg.MsgID)
	index[msg.MsgID] = thread
	if msg.Outbound {
		thread.ApplyOutbound(msg.Date)
		for _, to := range msg.To {
			if !strings.EqualFold(to, myEmail) {
				store.TouchContact(to, "", msg.Date)
				addParticipant(thread, to)
			}
		}
	} else {
		thread.ApplyInbound(msg.Date)
		store.TouchContact(msg.From, "", msg.Date)
		addParticipant(thread, msg.From)
	}
}

func addParticipant(t *Thread, email string) {
	email = strings.ToLower(email)
	for _, p := range t.Participants {
		if p == email {
			return
		}
	}
	t.Participants = append(t.Participants, email)
}

func parseRawMessage(header, text []byte, myEmail string) (*Message, []string) {
	if len(header) == 0 {
		return nil, nil
	}
	parsed, err := mail.ReadMessage(bytes.NewReader(append(header, '\n')))
	if err != nil {
		return nil, nil
	}
	h := parsed.Header
	msgID := canonicalMsgID(h.Get("Message-Id"))
	if msgID == "" {
		return nil, nil
	}
	msg := &Message{
		MsgID:   msgID,
		Subject: decodeHeader(h.Get("Subject")),
		Body:    extractPlainText(text, h.Get("Content-Type"), h.Get("Content-Transfer-Encoding")),
	}
	if date, derr := h.Date(); derr == nil {
		msg.Date = date
	} else {
		msg.Date = time.Now()
	}
	if from, ferr := mail.ParseAddress(h.Get("From")); ferr == nil {
		msg.From = strings.ToLower(from.Address)
	}
	for _, field := range []string{"To", "Cc"} {
		if addrs, aerr := h.AddressList(field); aerr == nil {
			for _, a := range addrs {
				msg.To = append(msg.To, strings.ToLower(a.Address))
			}
		}
	}
	msg.Outbound = strings.EqualFold(msg.From, myEmail)
	refs := msgIDList(h.Get("References"))
	refs = append(refs, msgIDList(h.Get("In-Reply-To"))...)
	return msg, refs
}

var msgIDPattern = regexp.MustCompile(`<[^<>\s]+>`)

func canonicalMsgID(raw string) string {
	if m := msgIDPattern.FindString(raw); m != "" {
		return m
	}
	return strings.TrimSpace(raw)
}

func msgIDList(raw string) []string {
	return msgIDPattern.FindAllString(raw, 20)
}

func decodeHeader(raw string) string {
	decoder := mime.WordDecoder{}
	if decoded, err := decoder.DecodeHeader(raw); err == nil {
		return decoded
	}
	return raw
}

func extractPlainText(body []byte, contentType, encoding string) string {
	mediaType, params, err := mime.ParseMediaType(contentType)
	if err != nil {
		mediaType = "text/plain"
	}
	var text string
	switch {
	case strings.HasPrefix(mediaType, "multipart/"):
		text = extractFromMultipart(body, params["boundary"], 0)
	case mediaType == "text/html":
		text = stripHTML(string(decodeBody(body, encoding)))
	default:
		text = string(decodeBody(body, encoding))
	}
	text = strings.TrimSpace(text)
	if len(text) > imapBodyKeepChars {
		text = text[:imapBodyKeepChars]
	}
	return text
}

func extractFromMultipart(body []byte, boundary string, depth int) string {
	if boundary == "" || depth > 3 {
		return ""
	}
	reader := multipart.NewReader(bytes.NewReader(body), boundary)
	htmlFallback := ""
	for i := 0; i < imapMaxMIMEParts; i++ {
		part, err := reader.NextPart()
		if err != nil {
			break
		}
		partType, partParams, _ := mime.ParseMediaType(part.Header.Get("Content-Type"))
		partBody, _ := io.ReadAll(io.LimitReader(part, imapTextBytes))
		encoding := part.Header.Get("Content-Transfer-Encoding")
		switch {
		case partType == "text/plain":
			return string(decodeBody(partBody, encoding))
		case partType == "text/html" && htmlFallback == "":
			htmlFallback = stripHTML(string(decodeBody(partBody, encoding)))
		case strings.HasPrefix(partType, "multipart/"):
			if nested := extractFromMultipart(partBody, partParams["boundary"], depth+1); nested != "" {
				return nested
			}
		}
	}
	return htmlFallback
}

func decodeBody(body []byte, encoding string) []byte {
	switch strings.ToLower(strings.TrimSpace(encoding)) {
	case "quoted-printable":
		decoded, err := io.ReadAll(quotedprintable.NewReader(bytes.NewReader(body)))
		if err != nil && len(decoded) == 0 {
			return body
		}
		return decoded
	case "base64":
		compact := strings.Map(func(r rune) rune {
			if r == '\n' || r == '\r' || r == ' ' {
				return -1
			}
			return r
		}, string(body))
		decoded, err := base64.StdEncoding.DecodeString(compact)
		if err != nil {
			if partial, perr := base64.StdEncoding.DecodeString(compact[:len(compact)-len(compact)%4]); perr == nil {
				return partial
			}
			return body
		}
		return decoded
	default:
		return body
	}
}

var (
	htmlTagPattern    = regexp.MustCompile(`(?s)<(script|style)[^>]*>.*?</(script|style)>|<[^>]*>`)
	htmlSpacePattern  = regexp.MustCompile(`[ \t]+`)
	htmlBlanksPattern = regexp.MustCompile(`\n{3,}`)
)

func stripHTML(html string) string {
	text := htmlTagPattern.ReplaceAllString(html, " ")
	text = strings.NewReplacer("&nbsp;", " ", "&amp;", "&", "&lt;", "<", "&gt;", ">", "&quot;", `"`, "&#39;", "'").Replace(text)
	text = htmlSpacePattern.ReplaceAllString(text, " ")
	return htmlBlanksPattern.ReplaceAllString(text, "\n\n")
}
