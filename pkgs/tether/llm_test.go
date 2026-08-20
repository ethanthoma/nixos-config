package main

import "testing"

func TestExtractJSON(t *testing.T) {
	cases := []struct{ in, want string }{
		{`{"state":"fyi"}`, `{"state":"fyi"}`},
		{"the answer is:\n{\"a\": {\"b\": 1}}\ntrailing", `{"a": {"b": 1}}`},
		{`{"note": "has } brace and \" quote in string"}`, `{"note": "has } brace and \" quote in string"}`},
	}
	for _, c := range cases {
		got, err := ExtractJSON(c.in)
		if err != nil || got != c.want {
			t.Fatalf("ExtractJSON(%q) = %q, %v; want %q", c.in, got, err, c.want)
		}
	}
	for _, bad := range []string{"no json here", `{"unterminated": true`} {
		if _, err := ExtractJSON(bad); err == nil {
			t.Fatalf("ExtractJSON(%q) should fail", bad)
		}
	}
}

func TestParseVerdict(t *testing.T) {
	v, err := parseVerdict(`reasoning... {"state": "needs_reply", "note": "bob asked a question", "commitments": []}`)
	if err != nil || v.State != ThreadNeedsReply {
		t.Fatalf("verdict: %+v, %v", v, err)
	}
	if _, err := parseVerdict(`{"state": "done", "note": "x"}`); err == nil {
		t.Fatal("done is not a valid triage verdict")
	}
}
