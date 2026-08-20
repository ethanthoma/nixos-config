package main

import (
	"strings"
	"testing"
	"time"
)

const plainHeader = "Message-Id: <a1@example.com>\r\n" +
	"From: Bob <bob@example.com>\r\n" +
	"To: Me <me@gmail.com>, Carol <carol@example.com>\r\n" +
	"Date: Mon, 17 Aug 2026 10:00:00 -0700\r\n" +
	"Subject: =?UTF-8?Q?caf=C3=A9_plans?=\r\n" +
	"In-Reply-To: <root@example.com>\r\n" +
	"References: <root@example.com> <mid@example.com>\r\n" +
	"Content-Type: text/plain; charset=utf-8\r\n" +
	"Content-Transfer-Encoding: quoted-printable\r\n"

func TestParseRawMessagePlain(t *testing.T) {
	msg, refs := parseRawMessage([]byte(plainHeader), []byte("see you at the caf=C3=A9 =\r\ntomorrow"), "me@gmail.com")
	if msg == nil {
		t.Fatal("parse returned nil")
	}
	if msg.MsgID != "<a1@example.com>" {
		t.Fatalf("msgid: %q", msg.MsgID)
	}
	if msg.Subject != "café plans" {
		t.Fatalf("encoded-word subject: %q", msg.Subject)
	}
	if msg.From != "bob@example.com" || msg.Outbound {
		t.Fatalf("from/outbound wrong: %q %v", msg.From, msg.Outbound)
	}
	if msg.Body != "see you at the café tomorrow" {
		t.Fatalf("quoted-printable body: %q", msg.Body)
	}
	if len(refs) != 3 {
		t.Fatalf("references+in-reply-to: %v", refs)
	}
}

func TestParseRawMessageOutbound(t *testing.T) {
	header := "Message-Id: <b@x>\r\nFrom: Me <ME@Gmail.com>\r\nTo: bob@example.com\r\n" +
		"Date: Mon, 17 Aug 2026 10:00:00 -0700\r\nSubject: re\r\nContent-Type: text/plain\r\n"
	msg, _ := parseRawMessage([]byte(header), []byte("on it"), "me@gmail.com")
	if msg == nil || !msg.Outbound {
		t.Fatalf("case-insensitive outbound detection failed: %+v", msg)
	}
}

func TestExtractMultipart(t *testing.T) {
	body := "--BOUND\r\nContent-Type: text/html\r\n\r\n<p>hi <b>there</b></p>\r\n" +
		"--BOUND\r\nContent-Type: text/plain\r\n\r\nhi there plain\r\n--BOUND--\r\n"
	got := extractPlainText([]byte(body), `multipart/alternative; boundary="BOUND"`, "")
	if strings.TrimSpace(got) != "hi there plain" {
		t.Fatalf("must prefer text/plain part: %q", got)
	}
}

func TestExtractHTMLFallback(t *testing.T) {
	got := extractPlainText([]byte("<html><style>p{}</style><p>hello &amp; welcome</p></html>"), "text/html", "")
	if !strings.Contains(got, "hello & welcome") || strings.Contains(got, "<p>") {
		t.Fatalf("html strip: %q", got)
	}
}

func TestApplyMessageThreading(t *testing.T) {
	s := testStore(t)
	index := s.ThreadByMsgID()
	first, _ := parseRawMessage([]byte(plainHeader), []byte("hi"), "me@gmail.com")
	applyMessage(s, index, first, nil, "me@gmail.com")
	if len(s.Threads) != 1 || s.Threads[0].State != ThreadNew {
		t.Fatalf("first message must open a new thread: %+v", s.Threads)
	}

	reply := &Message{MsgID: "<a2@example.com>", From: "me@gmail.com", To: []string{"bob@example.com"},
		Date: first.Date.Add(time.Hour), Outbound: true}
	applyMessage(s, index, reply, []string{"<a1@example.com>"}, "me@gmail.com")
	if len(s.Threads) != 1 {
		t.Fatalf("reply must join existing thread, got %d threads", len(s.Threads))
	}
	if s.Threads[0].State != ThreadWaitingOnThem {
		t.Fatalf("outbound reply: got %s, want waiting_on_them", s.Threads[0].State)
	}
	if s.ContactByEmail("bob@example.com") == nil {
		t.Fatal("counterparty contact not touched")
	}
}
