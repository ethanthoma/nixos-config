package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"time"
)

const (
	quietHourStart   = 22
	quietHourEnd     = 8
	maxPushesPerDay  = 5
	replyOverdue     = 48 * time.Hour
	replyCooldown    = 72 * time.Hour
	replyMaxFires    = 2
	bumpQuiet        = 5 * 24 * time.Hour
	staleCooldown    = 7 * 24 * time.Hour
	eventPrepWindow  = 24 * time.Hour
	reminderCooldown = 24 * time.Hour
	nudgeLogMaxAge   = 90 * 24 * time.Hour
)

type Nudge struct {
	RuleID   string    `json:"rule_id"`
	EntityID string    `json:"entity_id"`
	Title    string    `json:"-"`
	Body     string    `json:"-"`
	FiredAt  time.Time `json:"fired_at"`
}

type nudgeLog struct {
	path    string
	records []Nudge
}

func openNudgeLog(dir string) (*nudgeLog, error) {
	nl := &nudgeLog{path: filepath.Join(dir, "nudges.jsonl")}
	f, err := os.Open(nl.path)
	if os.IsNotExist(err) {
		return nl, nil
	}
	if err != nil {
		return nil, fmt.Errorf("nudges: open log: %w", err)
	}
	defer f.Close()
	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		var rec Nudge
		if err := json.Unmarshal(scanner.Bytes(), &rec); err == nil {
			nl.records = append(nl.records, rec)
		}
	}
	return nl, scanner.Err()
}

func (nl *nudgeLog) append(n Nudge) error {
	f, err := os.OpenFile(nl.path, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o600)
	if err != nil {
		return fmt.Errorf("nudges: append: %w", err)
	}
	defer f.Close()
	line, err := json.Marshal(n)
	if err != nil {
		return fmt.Errorf("nudges: marshal: %w", err)
	}
	if _, err := f.Write(append(line, '\n')); err != nil {
		return fmt.Errorf("nudges: write: %w", err)
	}
	nl.records = append(nl.records, n)
	return nil
}

func (nl *nudgeLog) firesWithin(ruleID, entityID string, window time.Duration, now time.Time) int {
	count := 0
	for _, rec := range nl.records {
		if rec.RuleID == ruleID && rec.EntityID == entityID && now.Sub(rec.FiredAt) < window {
			count++
		}
	}
	return count
}

func (nl *nudgeLog) firedToday(ruleID string, now time.Time) int {
	count := 0
	for _, rec := range nl.records {
		sameDay := rec.FiredAt.Local().Format("2006-01-02") == now.Local().Format("2006-01-02")
		if sameDay && (ruleID == "" || rec.RuleID == ruleID) {
			count++
		}
	}
	return count
}

func inQuietHours(now time.Time) bool {
	hour := now.Local().Hour()
	return hour >= quietHourStart || hour < quietHourEnd
}

func RunNudges(store *Store, cfg *Config, now time.Time) error {
	for _, c := range store.Commitments {
		c.Slip(now)
	}
	if err := store.Save(); err != nil {
		return err
	}
	if inQuietHours(now) {
		return nil
	}
	nl, err := openNudgeLog(store.dir)
	if err != nil {
		return err
	}
	for _, nudge := range collectNudges(store, nl, now) {
		if nl.firedToday("", now) >= maxPushesPerDay {
			log.Printf("nudge: daily cap reached, deferring %s/%s to digest", nudge.RuleID, nudge.EntityID)
			break
		}
		if err := NotifyNtfy(cfg, nudge.Title, nudge.Body); err != nil {
			return err
		}
		nudge.FiredAt = now
		if err := nl.append(nudge); err != nil {
			return err
		}
	}
	return nil
}

func collectNudges(store *Store, nl *nudgeLog, now time.Time) []Nudge {
	var out []Nudge

	for _, r := range store.Reminders {
		if r.State == ReminderOpen && !now.Before(r.Due) && nl.firesWithin("reminder", r.ID, reminderCooldown, now) == 0 {
			out = append(out, Nudge{RuleID: "reminder", EntityID: r.ID,
				Title: "Reminder", Body: r.Text})
		}
	}

	for _, c := range store.Commitments {
		age := ""
		switch {
		case c.State == CommitmentOpen && !c.Due.IsZero() && now.After(c.Due.Add(-24*time.Hour)) && now.Before(c.Due):
			age = "due_soon"
		case c.State == CommitmentSlipped:
			age = "slipped"
		}
		if age != "" && nl.firesWithin(age, c.ID, nudgeLogMaxAge, now) == 0 {
			title := "Commitment due soon"
			if age == "slipped" {
				title = "Commitment slipped"
			}
			out = append(out, Nudge{RuleID: age, EntityID: c.ID,
				Title: title, Body: fmt.Sprintf("%s (due %s)", c.Text, c.Due.Local().Format("Mon Jan 2"))})
		}
	}

	for _, t := range store.Threads {
		if t.Snoozed(now) {
			continue
		}
		if t.State == ThreadNeedsReply && now.Sub(t.LastInbound) > replyOverdue &&
			nl.firesWithin("needs_reply", t.ID, replyCooldown, now) == 0 &&
			nl.firesWithin("needs_reply", t.ID, nudgeLogMaxAge, now) < replyMaxFires {
			days := int(now.Sub(t.LastInbound).Hours() / 24)
			out = append(out, Nudge{RuleID: "needs_reply", EntityID: t.ID,
				Title: "Reply owed", Body: fmt.Sprintf("[%s] %s — waiting %dd for your reply", t.ShortID(), t.Subject, days)})
		}
		if t.State == ThreadWaitingOnThem && now.Sub(t.LastOutbound) > bumpQuiet &&
			nl.firesWithin("bump", t.ID, bumpQuiet, now) == 0 {
			days := int(now.Sub(t.LastOutbound).Hours() / 24)
			out = append(out, Nudge{RuleID: "bump", EntityID: t.ID,
				Title: "Worth a bump?", Body: fmt.Sprintf("[%s] %s — quiet for %dd", t.ShortID(), t.Subject, days)})
		}
	}

	staleToday := nl.firedToday("stale_contact", now)
	for _, c := range store.Contacts {
		if !c.Tracked || c.CadenceDays <= 0 {
			continue
		}
		overdue := now.Sub(c.LastContactAt) > time.Duration(c.CadenceDays)*24*time.Hour
		if overdue && staleToday == 0 && nl.firesWithin("stale_contact", c.Email, staleCooldown, now) == 0 {
			name := c.Name
			if name == "" {
				name = c.Email
			}
			days := int(now.Sub(c.LastContactAt).Hours() / 24)
			out = append(out, Nudge{RuleID: "stale_contact", EntityID: c.Email,
				Title: "Losing touch", Body: fmt.Sprintf("%s — no contact in %dd (cadence %dd)", name, days, c.CadenceDays)})
			staleToday++
		}
	}

	out = append(out, eventPrepNudges(store, nl, now)...)
	return out
}

func eventPrepNudges(store *Store, nl *nudgeLog, now time.Time) []Nudge {
	var out []Nudge
	for _, e := range store.Events {
		if e.Start.Before(now) || e.Start.After(now.Add(eventPrepWindow)) {
			continue
		}
		for _, t := range store.Threads {
			if t.State != ThreadNeedsReply || t.Snoozed(now) {
				continue
			}
			if !attendeeOverlap(e.Attendees, t.Participants) {
				continue
			}
			entity := e.UID + "|" + t.ShortID()
			if nl.firesWithin("event_prep", entity, nudgeLogMaxAge, now) == 0 {
				out = append(out, Nudge{RuleID: "event_prep", EntityID: entity,
					Title: "Before your meeting", Body: fmt.Sprintf("%q at %s — you still owe a reply on [%s] %s",
						e.Summary, e.Start.Local().Format("Mon 15:04"), t.ShortID(), t.Subject)})
			}
		}
	}
	return out
}

func attendeeOverlap(attendees, participants []string) bool {
	for _, a := range attendees {
		for _, p := range participants {
			if a == p {
				return true
			}
		}
	}
	return false
}
