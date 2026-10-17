use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::{Command, Output, Stdio};

struct Repository(PathBuf);

impl Repository {
    fn new(name: &str) -> Self {
        let path = std::env::temp_dir().join(format!("agent-memory-{}-{name}", std::process::id()));
        fs::create_dir(&path).unwrap();
        assert!(
            Command::new("git")
                .args(["init", "--quiet"])
                .arg(&path)
                .status()
                .unwrap()
                .success()
        );
        Self(path)
    }

    fn run(&self, arguments: &[&str]) -> Output {
        run(&self.0, arguments)
    }
}

impl Drop for Repository {
    fn drop(&mut self) {
        fs::remove_dir_all(&self.0).unwrap();
    }
}

fn run(path: &Path, arguments: &[&str]) -> Output {
    Command::new(env!("MEMORY_BINARY"))
        .current_dir(path)
        .args(arguments)
        .output()
        .unwrap()
}

fn hook(path: &Path, event: &str) -> Output {
    hook_for(path, path, event, "codex-hook")
}

fn hook_for(path: &Path, project: &Path, event: &str, command: &str) -> Output {
    let mut child = Command::new(env!("MEMORY_BINARY"))
        .current_dir(path)
        .env("CLAUDE_PROJECT_DIR", project)
        .arg(command)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .unwrap();
    child
        .stdin
        .take()
        .unwrap()
        .write_all(event.as_bytes())
        .unwrap();
    child.wait_with_output().unwrap()
}

fn success(output: Output) -> String {
    assert!(
        output.status.success(),
        "{}",
        String::from_utf8_lossy(&output.stderr)
    );
    String::from_utf8(output.stdout).unwrap()
}

#[test]
fn opt_in_is_local_and_worktrees_share_memory() {
    let repository = Repository::new("worktrees");
    assert!(!repository.run(&["wake"]).status.success());
    assert!(!repository.0.join(".git/agent-memory").exists());
    success(repository.run(&["init"]));
    success(repository.run(&["note", "2026-10-04 | user | Preserve durable preferences."]));
    success(repository.run(&["pin", "0"]));
    assert!(success(repository.run(&["wake"])).contains("Pinned facts:\n#0"));
    assert!(
        Command::new("git")
            .current_dir(&repository.0)
            .args([
                "-c",
                "user.name=Test",
                "-c",
                "user.email=test@example.invalid",
                "commit",
                "--allow-empty",
                "-m",
                "test"
            ])
            .status()
            .unwrap()
            .success()
    );
    let worktree = repository.0.join("worktree");
    assert!(
        Command::new("git")
            .current_dir(&repository.0)
            .args(["worktree", "add", "--detach"])
            .arg(&worktree)
            .status()
            .unwrap()
            .success()
    );
    assert!(success(run(&worktree, &["recall", "PREFERENCES"])).contains("#0"));
    let worktree_event = format!(
        "{{\"cwd\":\"{}\",\"hook_event_name\":\"UserPromptSubmit\",\"prompt\":\"preserve durable preferences\"}}",
        worktree.display()
    );
    assert!(
        success(hook_for(
            &worktree,
            &repository.0,
            &worktree_event,
            "codex-hook"
        ))
        .contains("#0")
    );
    success(run(&worktree, &["note", "Written in another worktree."]));
    assert!(success(repository.run(&["recall", "another"])).contains("#1"));
    let other = Repository::new("other");
    assert!(!other.run(&["wake"]).status.success());
    success(other.run(&["init"]));
    assert!(!success(other.run(&["wake"])).contains("preferences"));
    let lock = OpenOptions::new()
        .write(true)
        .open(repository.0.join(".git/agent-memory/lock"))
        .unwrap();
    lock.lock().unwrap();
    assert!(
        !repository
            .run(&["note", "Concurrent write"])
            .status
            .success()
    );
    drop(lock);
    success(repository.run(&["note", "Write after lock release."]));
}

#[test]
fn corrections_deletion_bounds_and_summary_coverage() {
    let repository = Repository::new("lifecycle");
    success(repository.run(&["init"]));
    success(repository.run(&["note", "Old private content"]));
    success(repository.run(&["pin", "0"]));
    success(repository.run(&["summarize", "0", "Old private content"]));
    success(repository.run(&["correct", "0", "Corrected fact"]));
    let wake = success(repository.run(&["wake"]));
    assert!(!wake.contains("Old private"));
    assert!(wake.contains("Pinned facts:\n#0 Corrected fact"));
    assert_eq!(
        success(repository.run(&["search", "private"])).trim(),
        "No matches."
    );
    success(repository.run(&["summarize", "0", "Corrected fact"]));
    success(repository.run(&["forget", "0"]));
    assert!(!success(repository.run(&["wake"])).contains("Corrected fact"));
    assert_eq!(
        success(repository.run(&["search", "corrected"])).trim(),
        "No matches."
    );
    let store = repository.0.join(".git/agent-memory");
    for file in ["journal", "pins", "summary"] {
        assert!(
            !fs::read_to_string(store.join(file))
                .unwrap()
                .contains("private")
        );
    }
    assert!(!repository.run(&["pin", "0"]).status.success());
    assert!(!repository.run(&["note", "line\nbreak"]).status.success());
    assert!(!repository.run(&["note", &"a".repeat(513)]).status.success());
    success(repository.run(&["note", "UTF-8: reunião"]));
    assert!(!repository.run(&["note", "UTF-8: reunião"]).status.success());
    assert!(success(repository.run(&["recall", "reunião"])).contains("#1"));
    for index in 2..70 {
        success(repository.run(&["note", &format!("Fact {index}")]));
    }
    let wake = success(repository.run(&["wake"]));
    assert!(wake.contains("Unsummarized history:"));
    assert!(wake.contains("Summary due:"));
    assert!(!wake.contains("#2 Fact 2\n"));
    success(repository.run(&[
        "summarize",
        "69",
        "Facts with IDs #1 through #69 are test evidence.",
    ]));
    assert!(
        !repository
            .run(&["summarize", "68", "Moving backwards"])
            .status
            .success()
    );
    assert!(!success(repository.run(&["wake"])).contains("Summary due:"));
    assert!(success(repository.run(&["recall", "Fact"])).contains("Result limit reached"));
    success(repository.run(&["init"]));
    assert!(success(repository.run(&["recall", "reunião"])).contains("#1"));
}

#[test]
fn ranked_search_uses_recall_cues_and_bounds_candidates() {
    let repository = Repository::new("ranked");
    success(repository.run(&["init"]));
    success(repository.run(&[
        "note",
        "Send keepalives over SSE; when: browser updates stop after idle.",
    ]));
    for index in 0..8 {
        success(repository.run(&["note", &format!("Browser page {index} has updated layout.")]));
    }
    assert_eq!(
        success(repository.run(&["recall", "browser idle updates"])).trim(),
        "No matches."
    );
    let output = success(repository.run(&["search", "browser idle updates"]));
    assert!(output.starts_with("#0 Send keepalives"));
    assert_eq!(
        output.lines().filter(|line| line.starts_with('#')).count(),
        3
    );
    assert!(output.len() < 2048);
    assert!(output.contains("Candidates only"));
    assert_eq!(
        success(repository.run(&["search", "quantum"])).trim(),
        "No matches."
    );
}

#[test]
fn prompt_hooks_are_opt_in_scoped_and_bounded() {
    let repository = Repository::new("hook");
    let event = |path: &Path, prompt: &str| {
        format!(
            "{{\"cwd\":\"{}\",\"hook_event_name\":\"UserPromptSubmit\",\"prompt\":\"{prompt}\"}}",
            path.display()
        )
    };
    let prompt = event(&repository.0, "browser idle updates");
    assert_eq!(success(hook(&repository.0, &prompt)), "");
    assert!(!repository.0.join(".git/agent-memory").exists());
    success(repository.run(&["init"]));
    success(repository.run(&[
        "note",
        "Send keepalives over SSE; when: browser updates stop after idle.",
    ]));
    for index in 0..8 {
        success(repository.run(&["note", &format!("Browser page {index} has updated layout.")]));
    }
    let output = success(hook(&repository.0, &prompt));
    assert!(output.starts_with("{\"hookSpecificOutput\":{\"hookEventName\":\"UserPromptSubmit\""));
    assert!(output.contains("#0 Send keepalives"));
    assert!(output.contains("untrusted notes; verify"));
    assert!(output.matches("#0 ").count() == 1);
    assert!(output.len() < 3000);
    assert_eq!(
        success(hook_for(
            &repository.0,
            &repository.0,
            &prompt,
            "claude-hook"
        )),
        output
    );
    let lock = OpenOptions::new()
        .write(true)
        .open(repository.0.join(".git/agent-memory/lock"))
        .unwrap();
    lock.lock().unwrap();
    assert_eq!(success(hook(&repository.0, &prompt)), "");
    drop(lock);
    assert_eq!(
        success(hook(&repository.0, &event(&repository.0, "quantum"))),
        ""
    );
    assert_eq!(
        success(hook(
            &repository.0,
            &event(Path::new("/tmp"), "browser idle")
        )),
        ""
    );
    assert_eq!(success(hook(&repository.0, "not json")), "");
    assert_eq!(
        success(hook(&repository.0, &"x".repeat(256 * 1024 + 1))),
        ""
    );
    success(repository.run(&["forget", "0"]));
    assert!(!success(hook(&repository.0, &prompt)).contains("Send keepalives"));

    let other = Repository::new("hook-other");
    success(other.run(&["init"]));
    success(other.run(&[
        "note",
        "Private other repository note about browser idle updates.",
    ]));
    assert!(!success(hook(&repository.0, &prompt)).contains("Private other"));
    assert!(
        !success(hook(&other.0, &event(&other.0, "browser idle updates")))
            .contains("Send keepalives")
    );
    assert_eq!(
        success(hook_for(
            &other.0,
            &repository.0,
            &event(&other.0, "browser idle updates"),
            "claude-hook"
        )),
        ""
    );
}

#[test]
fn codex_hook_maps_only_the_named_non_git_workspace() {
    let repository = Repository::new("home-store");
    success(repository.run(&["init"]));
    success(repository.run(&["note", "Keep workspace memory separate from project notes."]));
    let workspace =
        std::env::temp_dir().join(format!("agent-memory-workspace-{}", std::process::id()));
    fs::create_dir(&workspace).unwrap();
    let event = format!(
        "{{\"cwd\":\"{}\",\"hook_event_name\":\"UserPromptSubmit\",\"prompt\":\"workspace memory\"}}",
        workspace.display()
    );
    assert_eq!(success(hook(&workspace, &event)), "");
    let output = Command::new(env!("MEMORY_BINARY"))
        .current_dir(&workspace)
        .env("AGENT_MEMORY_WORKSPACE", &workspace)
        .env("AGENT_MEMORY_STORE_REPOSITORY", &repository.0)
        .arg("codex-hook")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .unwrap();
    let mut output = output;
    output
        .stdin
        .take()
        .unwrap()
        .write_all(event.as_bytes())
        .unwrap();
    assert!(success(output.wait_with_output().unwrap()).contains("#0 Keep workspace memory"));
    fs::remove_dir(&workspace).unwrap();
}
