package main

import (
	"testing"
	"time"
)

func testStore(t *testing.T) *Store {
	t.Helper()
	s, err := OpenStore(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { s.Close() })
	return s
}

func TestThreadTransitions(t *testing.T) {
	now := time.Now()
	thread := &Thread{ID: "<a@x>", State: ThreadNeedsReply}

	thread.ApplyOutbound(now)
	if thread.State != ThreadWaitingOnThem {
		t.Fatalf("outbound on needs_reply: got %s, want waiting_on_them", thread.State)
	}
	thread.ApplyInbound(now.Add(time.Hour))
	if thread.State != ThreadNew {
		t.Fatalf("inbound re-news: got %s, want new", thread.State)
	}
	thread.State = ThreadNoise
	thread.ApplyInbound(now.Add(2 * time.Hour))
	if thread.State != ThreadNoise {
		t.Fatalf("inbound must not resurrect noise: got %s", thread.State)
	}
	thread.State = ThreadDone
	thread.ApplyInbound(now.Add(3 * time.Hour))
	if thread.State != ThreadNew {
		t.Fatalf("inbound reopens done: got %s, want new", thread.State)
	}
}

func TestCommitmentSlip(t *testing.T) {
	now := time.Now()
	c := &Commitment{ID: "x", State: CommitmentOpen, Due: now.Add(-2 * time.Hour)}
	if c.Slip(now) {
		t.Fatal("slipped inside 24h grace")
	}
	if !c.Slip(now.Add(25 * time.Hour)) {
		t.Fatal("did not slip past grace")
	}
	if c.State != CommitmentSlipped {
		t.Fatalf("got %s, want slipped", c.State)
	}
	if c.Slip(now.Add(48 * time.Hour)) {
		t.Fatal("slip must not fire twice")
	}
	undated := &Commitment{ID: "y", State: CommitmentOpen}
	if undated.Slip(now.Add(999 * time.Hour)) {
		t.Fatal("undated commitment must never slip")
	}
}

func TestStoreRoundtrip(t *testing.T) {
	dir := t.TempDir()
	now := time.Now().Truncate(time.Second)
	s, err := OpenStore(dir)
	if err != nil {
		t.Fatal(err)
	}
	s.Threads = append(s.Threads, &Thread{ID: "<a@x>", State: ThreadNeedsReply, Subject: "hey", LastInbound: now, MsgIDs: []string{"<a@x>"}})
	s.Reminders = append(s.Reminders, &Reminder{ID: "r1", Text: "water plants", Due: now, State: ReminderOpen})
	if err := s.SaveMessage(&Message{MsgID: "<a@x>", From: "b@y", Body: "hello", Date: now}); err != nil {
		t.Fatal(err)
	}
	if err := s.Save(); err != nil {
		t.Fatal(err)
	}
	s.Close()

	loaded, err := OpenStore(dir)
	if err != nil {
		t.Fatal(err)
	}
	defer loaded.Close()
	if len(loaded.Threads) != 1 || loaded.Threads[0].State != ThreadNeedsReply {
		t.Fatalf("threads did not roundtrip: %+v", loaded.Threads)
	}
	if !loaded.Threads[0].LastInbound.Equal(now) {
		t.Fatalf("time did not roundtrip: %v vs %v", loaded.Threads[0].LastInbound, now)
	}
	msg, err := loaded.LoadMessage("<a@x>")
	if err != nil || msg.Body != "hello" {
		t.Fatalf("message cache did not roundtrip: %v %+v", err, msg)
	}
	if _, err := loaded.ThreadByShortID(loaded.Threads[0].ShortID()[:4]); err != nil {
		t.Fatalf("short id prefix lookup failed: %v", err)
	}
}

func TestTouchContact(t *testing.T) {
	s := testStore(t)
	early := time.Now().Add(-time.Hour)
	late := time.Now()
	s.TouchContact("A@X.com", "Alice", late)
	s.TouchContact("a@x.com", "", early)
	if len(s.Contacts) != 1 {
		t.Fatalf("case-insensitive dedup failed: %d contacts", len(s.Contacts))
	}
	if !s.Contacts[0].LastContactAt.Equal(late) {
		t.Fatal("older touch must not move LastContactAt backwards")
	}
}
