package main

import (
	"fmt"
	"io"
	"net/http"
	"sort"
	"strconv"
	"strings"
	"time"
)

const (
	icsWindowForward   = 14 * 24 * time.Hour
	icsWindowBack      = 24 * time.Hour
	icsMaxBodyBytes    = 8 << 20
	icsMaxOccurrences  = 500
	icsFetchTimeout    = 30 * time.Second
	icsSupportedFreqs  = "DAILY WEEKLY MONTHLY"
	icsMaxEventsStored = 200
)

func FetchCalendar(url string, now time.Time) ([]Event, error) {
	client := &http.Client{Timeout: icsFetchTimeout}
	resp, err := client.Get(url)
	if err != nil {
		return nil, fmt.Errorf("ics: fetch: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("ics: fetch: status %s", resp.Status)
	}
	data, err := io.ReadAll(io.LimitReader(resp.Body, icsMaxBodyBytes))
	if err != nil {
		return nil, fmt.Errorf("ics: read: %w", err)
	}
	return ParseICS(string(data), now)
}

type icsProp struct {
	params map[string]string
	value  string
}

func ParseICS(raw string, now time.Time) ([]Event, error) {
	windowStart := now.Add(-icsWindowBack)
	windowEnd := now.Add(icsWindowForward)
	var events []Event
	for _, block := range icsEventBlocks(icsUnfold(raw)) {
		events = append(events, icsExpandEvent(block, windowStart, windowEnd)...)
		if len(events) >= icsMaxEventsStored {
			events = events[:icsMaxEventsStored]
			break
		}
	}
	sort.Slice(events, func(i, j int) bool { return events[i].Start.Before(events[j].Start) })
	return events, nil
}

func icsUnfold(raw string) []string {
	raw = strings.ReplaceAll(raw, "\r\n", "\n")
	var lines []string
	for _, line := range strings.Split(raw, "\n") {
		if len(line) > 0 && (line[0] == ' ' || line[0] == '\t') && len(lines) > 0 {
			lines[len(lines)-1] += line[1:]
		} else {
			lines = append(lines, line)
		}
	}
	return lines
}

func icsEventBlocks(lines []string) []map[string][]icsProp {
	var blocks []map[string][]icsProp
	var current map[string][]icsProp
	depth := 0
	for _, line := range lines {
		switch {
		case line == "BEGIN:VEVENT":
			current = map[string][]icsProp{}
			depth = 0
		case line == "END:VEVENT" && current != nil && depth == 0:
			blocks = append(blocks, current)
			current = nil
		case strings.HasPrefix(line, "BEGIN:") && current != nil:
			depth++
		case strings.HasPrefix(line, "END:") && current != nil:
			depth--
		case current != nil && depth == 0:
			name, prop, ok := icsParseLine(line)
			if ok {
				current[name] = append(current[name], prop)
			}
		}
	}
	return blocks
}

func icsParseLine(line string) (string, icsProp, bool) {
	colon := -1
	inQuotes := false
	for i, r := range line {
		if r == '"' {
			inQuotes = !inQuotes
		}
		if r == ':' && !inQuotes {
			colon = i
			break
		}
	}
	if colon < 0 {
		return "", icsProp{}, false
	}
	nameAndParams := strings.Split(line[:colon], ";")
	prop := icsProp{params: map[string]string{}, value: line[colon+1:]}
	for _, p := range nameAndParams[1:] {
		if k, v, found := strings.Cut(p, "="); found {
			prop.params[strings.ToUpper(k)] = strings.Trim(v, "\"")
		}
	}
	return strings.ToUpper(nameAndParams[0]), prop, true
}

func icsUnescape(v string) string {
	r := strings.NewReplacer("\\n", "\n", "\\N", "\n", "\\,", ",", "\\;", ";", "\\\\", "\\")
	return r.Replace(v)
}

func icsParseTime(prop icsProp) (t time.Time, allDay bool, err error) {
	v := prop.value
	if prop.params["VALUE"] == "DATE" || len(v) == 8 {
		t, err = time.ParseInLocation("20060102", v, time.Local)
		return t, true, err
	}
	if strings.HasSuffix(v, "Z") {
		t, err = time.Parse("20060102T150405Z", v)
		return t, false, err
	}
	loc := time.Local
	if tzid := prop.params["TZID"]; tzid != "" {
		if l, lerr := time.LoadLocation(tzid); lerr == nil {
			loc = l
		}
	}
	t, err = time.ParseInLocation("20060102T150405", v, loc)
	return t, false, err
}

func icsExpandEvent(block map[string][]icsProp, windowStart, windowEnd time.Time) []Event {
	if props := block["STATUS"]; len(props) > 0 && props[0].value == "CANCELLED" {
		return nil
	}
	starts := block["DTSTART"]
	if len(starts) == 0 {
		return nil
	}
	start, allDay, err := icsParseTime(starts[0])
	if err != nil {
		return nil
	}
	duration := 0 * time.Second
	if allDay {
		duration = 24 * time.Hour
	}
	if ends := block["DTEND"]; len(ends) > 0 {
		if end, _, eerr := icsParseTime(ends[0]); eerr == nil && end.After(start) {
			duration = end.Sub(start)
		}
	}
	base := Event{AllDay: allDay}
	if props := block["UID"]; len(props) > 0 {
		base.UID = props[0].value
	}
	if props := block["SUMMARY"]; len(props) > 0 {
		base.Summary = icsUnescape(props[0].value)
	}
	for _, a := range block["ATTENDEE"] {
		if email, found := strings.CutPrefix(strings.ToLower(a.value), "mailto:"); found {
			base.Attendees = append(base.Attendees, email)
		}
	}
	excluded := map[string]bool{}
	for _, ex := range block["EXDATE"] {
		for _, v := range strings.Split(ex.value, ",") {
			if t, _, xerr := icsParseTime(icsProp{params: ex.params, value: v}); xerr == nil {
				excluded[t.UTC().Format(time.RFC3339)] = true
			}
		}
	}
	occurrences := icsOccurrences(block["RRULE"], start, windowEnd)
	var events []Event
	for _, occ := range occurrences {
		if excluded[occ.UTC().Format(time.RFC3339)] {
			continue
		}
		end := occ.Add(duration)
		if end.Before(windowStart) || occ.After(windowEnd) {
			continue
		}
		e := base
		e.Start = occ
		e.End = end
		events = append(events, e)
	}
	return events
}

func icsOccurrences(rrules []icsProp, start, windowEnd time.Time) []time.Time {
	if len(rrules) == 0 {
		return []time.Time{start}
	}
	rule := map[string]string{}
	for _, part := range strings.Split(rrules[0].value, ";") {
		if k, v, found := strings.Cut(part, "="); found {
			rule[strings.ToUpper(k)] = strings.ToUpper(v)
		}
	}
	freq := rule["FREQ"]
	if !strings.Contains(icsSupportedFreqs, freq) || freq == "" {
		return []time.Time{start}
	}
	interval := 1
	if v, err := strconv.Atoi(rule["INTERVAL"]); err == nil && v > 0 {
		interval = v
	}
	count := icsMaxOccurrences
	if v, err := strconv.Atoi(rule["COUNT"]); err == nil && v > 0 && v < count {
		count = v
	}
	until := windowEnd
	if v := rule["UNTIL"]; v != "" {
		if t, _, err := icsParseTime(icsProp{params: map[string]string{}, value: v}); err == nil && t.Before(until) {
			until = t
		}
	}
	step := func(t time.Time, n int) time.Time {
		switch freq {
		case "DAILY":
			return t.AddDate(0, 0, n*interval)
		case "WEEKLY":
			return t.AddDate(0, 0, 7*n*interval)
		default:
			return t.AddDate(0, n*interval, 0)
		}
	}
	byday := icsWeekdays(rule["BYDAY"])
	var out []time.Time
	for i := 0; i < icsMaxOccurrences && len(out) < count; i++ {
		occ := step(start, i)
		if occ.After(until) {
			break
		}
		if freq == "WEEKLY" && len(byday) > 0 {
			weekStart := occ.AddDate(0, 0, -int((occ.Weekday()+6)%7))
			for d := 0; d < 7 && len(out) < count; d++ {
				day := weekStart.AddDate(0, 0, d)
				if byday[day.Weekday()] && !day.Before(start) && !day.After(until) {
					out = append(out, day)
				}
			}
		} else {
			out = append(out, occ)
		}
	}
	return out
}

func icsWeekdays(byday string) map[time.Weekday]bool {
	names := map[string]time.Weekday{"SU": time.Sunday, "MO": time.Monday, "TU": time.Tuesday,
		"WE": time.Wednesday, "TH": time.Thursday, "FR": time.Friday, "SA": time.Saturday}
	out := map[time.Weekday]bool{}
	for _, d := range strings.Split(byday, ",") {
		if len(d) >= 2 {
			if wd, ok := names[d[len(d)-2:]]; ok {
				out[wd] = true
			}
		}
	}
	if byday == "" {
		return nil
	}
	return out
}
