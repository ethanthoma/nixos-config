package main

import (
	"fmt"
	"log"
	"os"
	"sort"
	"strconv"
	"strings"
	"time"
)

type Config struct {
	StateDir       string
	IMAPUser       string
	IMAPPassword   string
	MyEmail        string
	ICSURL         string
	NtfyTopic      string
	DiscordWebhook string
	LLMURL         string
	LLMKey         string
}

func loadConfig() *Config {
	env := func(key, fallback string) string {
		if v := os.Getenv(key); v != "" {
			return v
		}
		return fallback
	}
	cfg := &Config{
		StateDir:       env("TETHER_STATE_DIR", "/var/lib/tether"),
		IMAPUser:       os.Getenv("TETHER_IMAP_USER"),
		IMAPPassword:   os.Getenv("TETHER_IMAP_PASSWORD"),
		ICSURL:         os.Getenv("TETHER_ICS_URL"),
		NtfyTopic:      os.Getenv("TETHER_NTFY_TOPIC"),
		DiscordWebhook: os.Getenv("TETHER_DISCORD_WEBHOOK"),
		LLMURL:         env("TETHER_LLM_URL", "http://127.0.0.1:8080"),
		LLMKey:         os.Getenv("LLAMA_API_KEY"),
	}
	cfg.MyEmail = env("TETHER_MY_EMAIL", cfg.IMAPUser)
	return cfg
}

func (cfg *Config) require(fields map[string]string) {
	for name, value := range fields {
		if value == "" {
			log.Fatalf("missing required env %s", name)
		}
	}
}

const usage = `usage: tether <command>
  sync                       fetch new mail (IMAP) and calendar (ICS)
  triage                     LLM-classify new threads, extract commitments
  nudge                      evaluate nudge rules, push via ntfy
  digest                     post morning digest to Discord + ntfy ping
  pulse                      sync + triage + nudge (what the timer runs)
  ask "<question>"           ask the LLM a question over the store
  list [threads|commitments|contacts|reminders]
  done <id>                  close a thread / keep a commitment / finish a reminder
  snooze <id> <dur>          snooze a thread (e.g. 3d, 12h)
  track <email> [cadence-days]   track a contact for staleness (default 60)
  remind "<text>" <when>     add a reminder (when: YYYY-MM-DD, today, tomorrow, 3d)
`

func main() {
	log.SetFlags(0)
	if len(os.Args) < 2 {
		fmt.Print(usage)
		os.Exit(2)
	}
	cfg := loadConfig()
	now := time.Now()
	store, err := OpenStore(cfg.StateDir)
	if err != nil {
		log.Fatal(err)
	}
	defer store.Close()

	command := os.Args[1]
	args := os.Args[2:]
	switch command {
	case "sync":
		cmdSync(store, cfg, now)
	case "triage":
		cfg.require(map[string]string{"LLAMA_API_KEY": cfg.LLMKey})
		fatalIf(RunTriage(store, cfg, now))
	case "nudge":
		cfg.require(map[string]string{"TETHER_NTFY_TOPIC": cfg.NtfyTopic})
		fatalIf(RunNudges(store, cfg, now))
	case "digest":
		cfg.require(map[string]string{"TETHER_NTFY_TOPIC": cfg.NtfyTopic, "TETHER_DISCORD_WEBHOOK": cfg.DiscordWebhook})
		fatalIf(RunDigest(store, cfg, now))
	case "pulse":
		cfg.require(map[string]string{"TETHER_NTFY_TOPIC": cfg.NtfyTopic, "LLAMA_API_KEY": cfg.LLMKey})
		cmdSync(store, cfg, now)
		fatalIf(RunTriage(store, cfg, now))
		fatalIf(RunNudges(store, cfg, now))
	case "ask":
		cfg.require(map[string]string{"LLAMA_API_KEY": cfg.LLMKey})
		requireArgs(args, 1, "ask \"<question>\"")
		cmdAsk(store, cfg, now, strings.Join(args, " "))
	case "list":
		what := "threads"
		if len(args) > 0 {
			what = args[0]
		}
		cmdList(store, now, what)
	case "done":
		requireArgs(args, 1, "done <id>")
		fatalIf(cmdDone(store, args[0]))
		fatalIf(store.Save())
	case "snooze":
		requireArgs(args, 2, "snooze <id> <dur>")
		fatalIf(cmdSnooze(store, now, args[0], args[1]))
		fatalIf(store.Save())
	case "track":
		requireArgs(args, 1, "track <email> [cadence-days]")
		fatalIf(cmdTrack(store, args))
		fatalIf(store.Save())
	case "remind":
		requireArgs(args, 2, "remind \"<text>\" <when>")
		fatalIf(cmdRemind(store, now, args[0], args[1]))
		fatalIf(store.Save())
	default:
		fmt.Print(usage)
		os.Exit(2)
	}
}

func fatalIf(err error) {
	if err != nil {
		log.Fatal(err)
	}
}

func requireArgs(args []string, n int, form string) {
	if len(args) < n {
		log.Fatalf("usage: tether %s", form)
	}
}

func cmdSync(store *Store, cfg *Config, now time.Time) {
	cfg.require(map[string]string{"TETHER_IMAP_USER": cfg.IMAPUser, "TETHER_IMAP_PASSWORD": cfg.IMAPPassword})
	added, err := SyncMail(store, cfg, now)
	if err != nil {
		fatalIf(fmt.Errorf("%w (synced %d messages first)", err, added))
	}
	if added > 0 {
		log.Printf("sync: %d new messages", added)
	}
	fatalIf(store.Save())
	if cfg.ICSURL != "" {
		events, err := FetchCalendar(cfg.ICSURL, now)
		fatalIf(err)
		store.Events = events
		store.Sync.ICSFetched = now
		fatalIf(store.Save())
	}
}

func cmdAsk(store *Store, cfg *Config, now time.Time, question string) {
	context := buildDigest(store, now) + "\nthread details:\n"
	for _, t := range store.Threads {
		if t.State == ThreadNoise || t.State == ThreadDone {
			continue
		}
		context += fmt.Sprintf("`%s` [%s] %s — %s (%s)\n",
			t.ShortID(), t.State, t.Subject, strings.Join(t.Participants, ","), t.TriageNote)
	}
	system := "Reasoning strength: low\nYou answer questions about the user's email threads, commitments, " +
		"reminders, calendar, and contacts using ONLY the provided state. Be terse and concrete; " +
		"reference threads by their `id`. Today is " + now.Format("2006-01-02, Monday") + "."
	answer, err := LLMChat(cfg, system, context+"\nquestion: "+question, 0.2, 1500)
	fatalIf(err)
	fmt.Println(strings.TrimSpace(answer))
}

func cmdList(store *Store, now time.Time, what string) {
	switch what {
	case "threads":
		sorted := append([]*Thread(nil), store.Threads...)
		sort.Slice(sorted, func(i, j int) bool {
			return latestActivity(sorted[i]).After(latestActivity(sorted[j]))
		})
		for _, t := range sorted {
			if t.State == ThreadNoise || t.State == ThreadDone {
				continue
			}
			flag := ""
			if t.Snoozed(now) {
				flag = " (snoozed)"
			}
			fmt.Printf("%s  %-15s %s%s\n", t.ShortID(), t.State, t.Subject, flag)
		}
	case "commitments":
		for _, c := range store.Commitments {
			due := "no due date"
			if !c.Due.IsZero() {
				due = c.Due.Local().Format("2006-01-02")
			}
			fmt.Printf("%s  %-8s %s (%s)\n", c.ID, c.State, c.Text, due)
		}
	case "contacts":
		for _, c := range store.Contacts {
			if !c.Tracked {
				continue
			}
			fmt.Printf("%-30s cadence %dd, last contact %s\n", c.Email, c.CadenceDays,
				c.LastContactAt.Local().Format("2006-01-02"))
		}
	case "reminders":
		for _, r := range store.Reminders {
			fmt.Printf("%s  %-5s %s (%s)\n", r.ID, r.State, r.Text, r.Due.Local().Format("2006-01-02"))
		}
	default:
		log.Fatalf("unknown list target %q", what)
	}
}

func latestActivity(t *Thread) time.Time {
	if t.LastOutbound.After(t.LastInbound) {
		return t.LastOutbound
	}
	return t.LastInbound
}

func cmdDone(store *Store, id string) error {
	if thread, err := store.ThreadByShortID(id); err == nil {
		thread.State = ThreadDone
		fmt.Printf("thread %s done: %s\n", thread.ShortID(), thread.Subject)
		return nil
	}
	for _, c := range store.Commitments {
		if c.ID == id {
			c.State = CommitmentKept
			fmt.Printf("commitment kept: %s\n", c.Text)
			return nil
		}
	}
	for _, r := range store.Reminders {
		if r.ID == id {
			r.State = ReminderDone
			fmt.Printf("reminder done: %s\n", r.Text)
			return nil
		}
	}
	return fmt.Errorf("nothing matches id %q", id)
}

func cmdSnooze(store *Store, now time.Time, id, duration string) error {
	thread, err := store.ThreadByShortID(id)
	if err != nil {
		return err
	}
	d, err := parseDuration(duration)
	if err != nil {
		return err
	}
	thread.SnoozeUntil = now.Add(d)
	fmt.Printf("thread %s snoozed until %s\n", thread.ShortID(), thread.SnoozeUntil.Local().Format("Jan 2 15:04"))
	return nil
}

func cmdTrack(store *Store, args []string) error {
	email := strings.ToLower(args[0])
	cadence := 60
	if len(args) > 1 {
		v, err := strconv.Atoi(args[1])
		if err != nil || v <= 0 {
			return fmt.Errorf("bad cadence %q, want positive days", args[1])
		}
		cadence = v
	}
	c := store.ContactByEmail(email)
	if c == nil {
		c = &Contact{Email: email}
		store.Contacts = append(store.Contacts, c)
	}
	c.Tracked = true
	c.CadenceDays = cadence
	fmt.Printf("tracking %s every %dd\n", email, cadence)
	return nil
}

func cmdRemind(store *Store, now time.Time, text, when string) error {
	due, err := parseWhen(now, when)
	if err != nil {
		return err
	}
	r := &Reminder{ID: CommitmentID("reminder", text+due.Format(time.RFC3339)), Text: text, Due: due, State: ReminderOpen}
	store.Reminders = append(store.Reminders, r)
	fmt.Printf("reminder %s set for %s\n", r.ID, due.Local().Format("Mon Jan 2 15:04"))
	return nil
}

func parseDuration(raw string) (time.Duration, error) {
	if strings.HasSuffix(raw, "d") {
		days, err := strconv.Atoi(strings.TrimSuffix(raw, "d"))
		if err != nil || days <= 0 {
			return 0, fmt.Errorf("bad duration %q", raw)
		}
		return time.Duration(days) * 24 * time.Hour, nil
	}
	d, err := time.ParseDuration(raw)
	if err != nil || d <= 0 {
		return 0, fmt.Errorf("bad duration %q (want 3d, 12h, ...)", raw)
	}
	return d, nil
}

func parseWhen(now time.Time, raw string) (time.Time, error) {
	atFive := func(t time.Time) time.Time {
		return time.Date(t.Year(), t.Month(), t.Day(), 17, 0, 0, 0, time.Local)
	}
	switch raw {
	case "today":
		return atFive(now), nil
	case "tomorrow":
		return atFive(now.AddDate(0, 0, 1)), nil
	}
	if t, err := time.ParseInLocation("2006-01-02", raw, time.Local); err == nil {
		return atFive(t), nil
	}
	if d, err := parseDuration(raw); err == nil {
		return now.Add(d), nil
	}
	return time.Time{}, fmt.Errorf("bad time %q (want YYYY-MM-DD, today, tomorrow, or 3d)", raw)
}
