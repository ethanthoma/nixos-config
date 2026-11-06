use std::io::{Read, Write};
use std::process::{Command, ExitCode, Stdio};

fn main() -> ExitCode {
    match export() {
        Ok(()) => ExitCode::SUCCESS,
        Err(_) => {
            eprintln!("Morph credential export failed");
            ExitCode::FAILURE
        }
    }
}

fn export() -> Result<(), Box<dyn std::error::Error>> {
    const KEY_BYTES_MAX: u64 = 4096;
    let mut child = Command::new(env!("PI_EXECUTABLE"))
        .args(["auth", "print-api-key", "--provider", "morph"])
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()?;
    let mut bytes = Vec::with_capacity(KEY_BYTES_MAX as usize + 1);
    let result = child
        .stdout
        .take()
        .ok_or("credential output unavailable")?
        .take(KEY_BYTES_MAX + 1)
        .read_to_end(&mut bytes);
    if result.is_err() || bytes.len() as u64 > KEY_BYTES_MAX {
        child.kill()?;
        child.wait()?;
        return Err("credential output invalid".into());
    }
    if !child.wait()?.success() {
        return Err("credential lookup failed".into());
    }
    let key = std::str::from_utf8(&bytes)?.trim_end_matches(['\r', '\n']);
    if key.is_empty()
        || !key
            .bytes()
            .all(|byte| matches!(byte, 33..=126) && byte != b'"' && byte != b'\\')
    {
        return Err("credential encoding invalid".into());
    }
    let mut output = std::io::stdout().lock();
    write!(
        output,
        "{{\"morph\":{{\"type\":\"api_key\",\"key\":\"{key}\"}}}}"
    )?;
    output.flush()?;
    Ok(())
}
