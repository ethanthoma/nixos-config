package main

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"syscall"
	"time"
)

type ThreadState string

const (
	ThreadNew           ThreadState = "new"
	ThreadNeedsReply    ThreadState = "needs_reply"
	ThreadWaitingOnThem ThreadState = "waiting_on_them"
	ThreadFYI           ThreadState = "fyi"
	ThreadNoise         ThreadState = "noise"
	ThreadDone          ThreadState = "done"
)

func (s ThreadState) valid() bool {
	switch s {
	case ThreadNew, ThreadNeedsReply, ThreadWaitingOnThem, ThreadFYI, ThreadNoise, ThreadDone:
		return true
	}
	return false
}

type Thread struct {
	ID             string      `json:"id"`
	State          ThreadState `json:"state"`
	SnoozeUntil    time.Time   `json:"snooze_until,omitzero"`
	Subject        string      `json:"subject"`
	Participants   []string    `json:"participants"`
	LastInbound    time.Time   `json:"last_inbound,omitzero"`
	LastOutbound   time.Time   `json:"last_outbound,omitzero"`
	TriageNote     string      `json:"triage_note,omitempty"`
	TriageAttempts int         `json:"triage_attempts,omitempty"`
	MsgIDs         []string    `json:"msg_ids"`
}

func (t *Thread) ShortID() string {
	sum := sha256.Sum256([]byte(t.ID))
	return hex.EncodeToString(sum[:4])
}

func (t *Thread) ApplyInbound(at time.Time) {
	if t.State != ThreadNoise {
		t.State = ThreadNew
	}
	if at.After(t.LastInbound) {
		t.LastInbound = at
	}
}

func (t *Thread) ApplyOutbound(at time.Time) {
	if t.State == ThreadNeedsReply || t.State == ThreadNew {
		t.State = ThreadWaitingOnThem
	}
	if at.After(t.LastOutbound) {
		t.LastOutbound = at
	}
}

func (t *Thread) Snoozed(now time.Time) bool {
	return now.Before(t.SnoozeUntil)
}

type CommitmentState string

const (
	CommitmentOpen    CommitmentState = "open"
	CommitmentKept    CommitmentState = "kept"
	CommitmentSlipped CommitmentState = "slipped"
	CommitmentDropped CommitmentState = "dropped"
)

type Commitment struct {
	ID       string          `json:"id"`
	Text     string          `json:"text"`
	ThreadID string          `json:"thread_id"`
	Due      time.Time       `json:"due,omitzero"`
	State    CommitmentState `json:"state"`
}

func CommitmentID(threadID, text string) string {
	sum := sha256.Sum256([]byte(threadID + "\x00" + text))
	return hex.EncodeToString(sum[:4])
}

const slipGrace = 24 * time.Hour

func (c *Commitment) Slip(now time.Time) bool {
	if c.State != CommitmentOpen {
		return false
	}
	if c.Due.IsZero() {
		return false
	}
	if now.Before(c.Due.Add(slipGrace)) {
		return false
	}
	c.State = CommitmentSlipped
	return true
}

type Contact struct {
	Email         string    `json:"email"`
	Name          string    `json:"name,omitempty"`
	Tracked       bool      `json:"tracked"`
	CadenceDays   int       `json:"cadence_days,omitempty"`
	LastContactAt time.Time `json:"last_contact_at,omitzero"`
}

type ReminderState string

const (
	ReminderOpen ReminderState = "open"
	ReminderDone ReminderState = "done"
)

type Reminder struct {
	ID    string        `json:"id"`
	Text  string        `json:"text"`
	Due   time.Time     `json:"due"`
	State ReminderState `json:"state"`
}

type Event struct {
	UID       string    `json:"uid"`
	Summary   string    `json:"summary"`
	Start     time.Time `json:"start"`
	End       time.Time `json:"end,omitzero"`
	AllDay    bool      `json:"all_day,omitempty"`
	Attendees []string  `json:"attendees,omitempty"`
}

type SyncState struct {
	UIDValidity uint32    `json:"uidvalidity"`
	LastUID     uint32    `json:"last_uid"`
	ICSFetched  time.Time `json:"ics_fetched,omitzero"`
	MailFetched time.Time `json:"mail_fetched,omitzero"`
}

type Message struct {
	MsgID    string    `json:"msg_id"`
	From     string    `json:"from"`
	To       []string  `json:"to"`
	Date     time.Time `json:"date"`
	Subject  string    `json:"subject"`
	Body     string    `json:"body"`
	Outbound bool      `json:"outbound"`
}

type Store struct {
	dir         string
	lockFile    *os.File
	Sync        SyncState
	Threads     []*Thread
	Contacts    []*Contact
	Commitments []*Commitment
	Reminders   []*Reminder
	Events      []Event
}

func OpenStore(dir string) (*Store, error) {
	if err := os.MkdirAll(filepath.Join(dir, "cache", "msg"), 0o700); err != nil {
		return nil, fmt.Errorf("store: mkdir: %w", err)
	}
	lockFile, err := os.OpenFile(filepath.Join(dir, "lock"), os.O_CREATE|os.O_RDWR, 0o600)
	if err != nil {
		return nil, fmt.Errorf("store: open lock: %w", err)
	}
	if err := syscall.Flock(int(lockFile.Fd()), syscall.LOCK_EX); err != nil {
		lockFile.Close()
		return nil, fmt.Errorf("store: flock: %w", err)
	}
	s := &Store{dir: dir, lockFile: lockFile}
	for name, dst := range s.files() {
		if err := loadJSON(filepath.Join(dir, name), dst); err != nil {
			lockFile.Close()
			return nil, err
		}
	}
	for _, t := range s.Threads {
		if !t.State.valid() {
			lockFile.Close()
			return nil, fmt.Errorf("store: thread %s has invalid state %q", t.ShortID(), t.State)
		}
	}
	return s, nil
}

func (s *Store) Close() error {
	return s.lockFile.Close()
}

func (s *Store) files() map[string]any {
	return map[string]any{
		"sync.json":        &s.Sync,
		"threads.json":     &s.Threads,
		"contacts.json":    &s.Contacts,
		"commitments.json": &s.Commitments,
		"reminders.json":   &s.Reminders,
		"calendar.json":    &s.Events,
	}
}

func (s *Store) Save() error {
	for name, src := range s.files() {
		if err := saveJSON(filepath.Join(s.dir, name), src); err != nil {
			return err
		}
	}
	return nil
}

func (s *Store) ThreadByMsgID() map[string]*Thread {
	index := make(map[string]*Thread, len(s.Threads)*4)
	for _, t := range s.Threads {
		for _, id := range t.MsgIDs {
			index[id] = t
		}
	}
	return index
}

func (s *Store) ThreadByShortID(prefix string) (*Thread, error) {
	var matches []*Thread
	for _, t := range s.Threads {
		if strings.HasPrefix(t.ShortID(), prefix) {
			matches = append(matches, t)
		}
	}
	if len(matches) == 0 {
		return nil, fmt.Errorf("no thread matches id %q", prefix)
	}
	if len(matches) > 1 {
		return nil, fmt.Errorf("id %q is ambiguous (%d matches)", prefix, len(matches))
	}
	return matches[0], nil
}

func (s *Store) ContactByEmail(email string) *Contact {
	email = strings.ToLower(email)
	for _, c := range s.Contacts {
		if c.Email == email {
			return c
		}
	}
	return nil
}

func (s *Store) TouchContact(email, name string, at time.Time) {
	email = strings.ToLower(email)
	if email == "" {
		return
	}
	c := s.ContactByEmail(email)
	if c == nil {
		c = &Contact{Email: email}
		s.Contacts = append(s.Contacts, c)
	}
	if name != "" && c.Name == "" {
		c.Name = name
	}
	if at.After(c.LastContactAt) {
		c.LastContactAt = at
	}
}

func (s *Store) msgPath(msgID string) string {
	sum := sha256.Sum256([]byte(msgID))
	return filepath.Join(s.dir, "cache", "msg", hex.EncodeToString(sum[:])+".json")
}

func (s *Store) SaveMessage(m *Message) error {
	return saveJSON(s.msgPath(m.MsgID), m)
}

func (s *Store) LoadMessage(msgID string) (*Message, error) {
	var m Message
	if err := loadJSON(s.msgPath(msgID), &m); err != nil {
		return nil, err
	}
	if m.MsgID == "" {
		return nil, fmt.Errorf("store: no cached message %q", msgID)
	}
	return &m, nil
}

func loadJSON(path string, dst any) error {
	data, err := os.ReadFile(path)
	if os.IsNotExist(err) {
		return nil
	}
	if err != nil {
		return fmt.Errorf("store: read %s: %w", path, err)
	}
	if err := json.Unmarshal(data, dst); err != nil {
		return fmt.Errorf("store: parse %s: %w", path, err)
	}
	return nil
}

func saveJSON(path string, src any) error {
	data, err := json.MarshalIndent(src, "", " ")
	if err != nil {
		return fmt.Errorf("store: marshal %s: %w", path, err)
	}
	tmp, err := os.CreateTemp(filepath.Dir(path), ".tmp-*")
	if err != nil {
		return fmt.Errorf("store: tmp for %s: %w", path, err)
	}
	defer os.Remove(tmp.Name())
	if _, err := tmp.Write(data); err != nil {
		tmp.Close()
		return fmt.Errorf("store: write %s: %w", path, err)
	}
	if err := tmp.Sync(); err != nil {
		tmp.Close()
		return fmt.Errorf("store: fsync %s: %w", path, err)
	}
	if err := tmp.Close(); err != nil {
		return fmt.Errorf("store: close %s: %w", path, err)
	}
	if err := os.Rename(tmp.Name(), path); err != nil {
		return fmt.Errorf("store: rename %s: %w", path, err)
	}
	return nil
}
