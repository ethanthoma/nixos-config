package main

import (
	"strings"
	"testing"
	"time"
)

const icsFixture = "BEGIN:VCALENDAR\r\n" +
	"BEGIN:VEVENT\r\nUID:one@google.com\r\nDTSTART:__PLAIN_START__\r\nDTEND:__PLAIN_END__\r\n" +
	"SUMMARY:Coffee with a very long name that goes on\r\n  and on across a folded line\r\n" +
	"ATTENDEE;CN=Bob:mailto:bob@example.com\r\nEND:VEVENT\r\n" +
	"BEGIN:VEVENT\r\nUID:allday@google.com\r\nDTSTART;VALUE=DATE:__ALLDAY__\r\nSUMMARY:Trip\r\nEND:VEVENT\r\n" +
	"BEGIN:VEVENT\r\nUID:weekly@google.com\r\nDTSTART:__WEEKLY_START__\r\n" +
	"RRULE:FREQ=WEEKLY;BYDAY=MO,TH\r\nSUMMARY:Standup\r\nEND:VEVENT\r\n" +
	"BEGIN:VEVENT\r\nUID:gone@google.com\r\nDTSTART:__PLAIN_START__\r\nSTATUS:CANCELLED\r\nSUMMARY:Cancelled\r\nEND:VEVENT\r\n" +
	"END:VCALENDAR\r\n"

func TestParseICS(t *testing.T) {
	now := time.Now()
	start := now.Add(24 * time.Hour).UTC()
	weeklyStart := now.Add(-30 * 24 * time.Hour).UTC()
	raw := strings.NewReplacer(
		"__PLAIN_START__", start.Format("20060102T150405Z"),
		"__PLAIN_END__", start.Add(time.Hour).Format("20060102T150405Z"),
		"__ALLDAY__", now.AddDate(0, 0, 2).Format("20060102"),
		"__WEEKLY_START__", weeklyStart.Format("20060102T150405Z"),
	).Replace(icsFixture)

	events, err := ParseICS(raw, now)
	if err != nil {
		t.Fatal(err)
	}
	byUID := map[string][]Event{}
	for _, e := range events {
		byUID[e.UID] = append(byUID[e.UID], e)
	}

	coffee := byUID["one@google.com"]
	if len(coffee) != 1 {
		t.Fatalf("plain event: got %d occurrences", len(coffee))
	}
	if !strings.Contains(coffee[0].Summary, "on and on across a folded line") {
		t.Fatalf("line unfolding broke summary: %q", coffee[0].Summary)
	}
	if len(coffee[0].Attendees) != 1 || coffee[0].Attendees[0] != "bob@example.com" {
		t.Fatalf("attendee parse: %v", coffee[0].Attendees)
	}
	if coffee[0].End.Sub(coffee[0].Start) != time.Hour {
		t.Fatalf("duration: %v", coffee[0].End.Sub(coffee[0].Start))
	}

	allday := byUID["allday@google.com"]
	if len(allday) != 1 || !allday[0].AllDay {
		t.Fatalf("all-day event: %+v", allday)
	}

	weekly := byUID["weekly@google.com"]
	if len(weekly) < 3 || len(weekly) > 6 {
		t.Fatalf("weekly MO,TH over 14d window: got %d occurrences", len(weekly))
	}
	for _, e := range weekly {
		wd := e.Start.Weekday()
		if wd != time.Monday && wd != time.Thursday {
			t.Fatalf("weekly occurrence on wrong day: %s", wd)
		}
	}

	if len(byUID["gone@google.com"]) != 0 {
		t.Fatal("cancelled event must be dropped")
	}
}

func TestParseICSBounds(t *testing.T) {
	now := time.Now()
	raw := "BEGIN:VEVENT\r\nUID:daily@x\r\nDTSTART:" + now.UTC().Format("20060102T150405Z") +
		"\r\nRRULE:FREQ=DAILY\r\nSUMMARY:Forever\r\nEND:VEVENT\r\n"
	events, err := ParseICS(raw, now)
	if err != nil {
		t.Fatal(err)
	}
	if len(events) == 0 || len(events) > 16 {
		t.Fatalf("unbounded daily rule must clip to window: got %d", len(events))
	}
}
