use std::path::PathBuf;

pub struct Event {
    pub cwd: PathBuf,
    pub prompt: String,
}

pub fn parse_event(input: &str) -> Option<Event> {
    let bytes = input.as_bytes();
    let mut index = whitespace(bytes, 0);
    if bytes.get(index)? != &b'{' {
        return None;
    }
    index += 1;
    let mut cwd = None;
    let mut prompt = None;
    let mut event = None;
    loop {
        index = whitespace(bytes, index);
        if bytes.get(index)? == &b'}' {
            index += 1;
            break;
        }
        let key = json_read_string(input, &mut index)?;
        index = whitespace(bytes, index);
        if bytes.get(index)? != &b':' {
            return None;
        }
        index = whitespace(bytes, index + 1);
        let value = if bytes.get(index)? == &b'"' {
            Some(json_read_string(input, &mut index)?)
        } else {
            json_skip_value(input, &mut index)?;
            None
        };
        match key.as_str() {
            "cwd" if cwd.is_none() => cwd = value,
            "prompt" if prompt.is_none() => prompt = value,
            "hook_event_name" if event.is_none() => event = value,
            "cwd" | "prompt" | "hook_event_name" => return None,
            _ => {}
        }
        index = whitespace(bytes, index);
        match bytes.get(index)? {
            b',' => index += 1,
            b'}' => {
                index += 1;
                break;
            }
            _ => return None,
        }
    }
    if whitespace(bytes, index) != bytes.len() || event.as_deref() != Some("UserPromptSubmit") {
        return None;
    }
    let cwd = PathBuf::from(cwd?);
    let prompt = prompt?;
    if !cwd.is_absolute() || prompt.trim().is_empty() {
        return None;
    }
    Some(Event { cwd, prompt })
}

pub fn search_query(prompt: &str) -> String {
    let mut query = String::new();
    for character in prompt.chars() {
        let character = if character.is_whitespace() {
            ' '
        } else {
            character
        };
        if query.len() + character.len_utf8() > 512 {
            break;
        }
        query.push(character);
    }
    query
}

pub fn json_string(value: &str) -> String {
    let mut encoded = String::from("\"");
    for character in value.chars() {
        match character {
            '"' => encoded.push_str("\\\""),
            '\\' => encoded.push_str("\\\\"),
            '\n' => encoded.push_str("\\n"),
            '\r' => encoded.push_str("\\r"),
            '\t' => encoded.push_str("\\t"),
            character if character.is_control() => {
                encoded.push_str(&format!("\\u{:04x}", character as u32))
            }
            character => encoded.push(character),
        }
    }
    encoded.push('"');
    encoded
}

fn whitespace(bytes: &[u8], mut index: usize) -> usize {
    while matches!(bytes.get(index), Some(b' ' | b'\n' | b'\r' | b'\t')) {
        index += 1;
    }
    index
}

fn json_read_string(input: &str, index: &mut usize) -> Option<String> {
    let bytes = input.as_bytes();
    if bytes.get(*index)? != &b'"' {
        return None;
    }
    *index += 1;
    let mut segment = *index;
    let mut decoded = String::new();
    while *index < bytes.len() {
        match bytes[*index] {
            b'"' => {
                decoded.push_str(input.get(segment..*index)?);
                *index += 1;
                return Some(decoded);
            }
            b'\\' => {
                decoded.push_str(input.get(segment..*index)?);
                *index += 1;
                let escaped = *bytes.get(*index)?;
                match escaped {
                    b'"' => decoded.push('"'),
                    b'\\' => decoded.push('\\'),
                    b'/' => decoded.push('/'),
                    b'b' => decoded.push('\u{0008}'),
                    b'f' => decoded.push('\u{000c}'),
                    b'n' => decoded.push('\n'),
                    b'r' => decoded.push('\r'),
                    b't' => decoded.push('\t'),
                    b'u' => {
                        let high = json_hex4(bytes, *index + 1)?;
                        *index += 4;
                        let code = if (0xd800..=0xdbff).contains(&high) {
                            if bytes.get(*index + 1..*index + 3)? != b"\\u" {
                                return None;
                            }
                            let low = json_hex4(bytes, *index + 3)?;
                            if !(0xdc00..=0xdfff).contains(&low) {
                                return None;
                            }
                            *index += 6;
                            0x10000 + ((high as u32 - 0xd800) << 10) + low as u32 - 0xdc00
                        } else {
                            high as u32
                        };
                        decoded.push(char::from_u32(code)?);
                    }
                    _ => return None,
                }
                *index += 1;
                segment = *index;
            }
            0..=31 => return None,
            _ => *index += 1,
        }
    }
    None
}

fn json_hex4(bytes: &[u8], start: usize) -> Option<u16> {
    let mut value = 0_u16;
    for byte in bytes.get(start..start + 4)? {
        value = (value << 4) | (*byte as char).to_digit(16)? as u16;
    }
    Some(value)
}

fn json_skip_value(input: &str, index: &mut usize) -> Option<()> {
    let bytes = input.as_bytes();
    let mut stack = Vec::new();
    match bytes.get(*index)? {
        b'{' => stack.push(b'}'),
        b'[' => stack.push(b']'),
        _ => {
            let start = *index;
            while !matches!(bytes.get(*index), None | Some(b',' | b'}')) {
                *index += 1;
            }
            let value = input.get(start..*index)?.trim();
            return (matches!(value, "true" | "false" | "null")
                || value.parse::<f64>().is_ok_and(f64::is_finite))
            .then_some(());
        }
    }
    *index += 1;
    while *index < bytes.len() {
        match bytes[*index] {
            b'"' => {
                json_read_string(input, index)?;
                continue;
            }
            b'{' => stack.push(b'}'),
            b'[' => stack.push(b']'),
            b'}' | b']' => {
                if stack.pop()? != bytes[*index] {
                    return None;
                }
                *index += 1;
                if stack.is_empty() {
                    return Some(());
                }
                continue;
            }
            _ => {}
        }
        if stack.len() > 32 {
            return None;
        }
        *index += 1;
    }
    None
}

#[cfg(test)]
mod tests {
    use super::{json_skip_value, json_string, parse_event, search_query};

    #[test]
    fn reads_top_level_prompt_and_unicode_escapes() {
        let nested = r#"{"prompt":"wrong"},"cwd""#;
        let mut index = 0;
        assert!(json_skip_value(nested, &mut index).is_some());
        assert_eq!(index, nested.find(',').unwrap());
        assert!(
            parse_event(
                r#"{"cwd":"/tmp/repo","hook_event_name":"UserPromptSubmit","prompt":"fix"}"#
            )
            .is_some()
        );
        assert!(parse_event(r#"{"count":3,"cwd":"/tmp/repo","hook_event_name":"UserPromptSubmit","prompt":"fix"}"#).is_some());
        assert!(parse_event(r#"{"nested":{"prompt":"wrong"},"cwd":"/tmp/repo","hook_event_name":"UserPromptSubmit","prompt":"fix"}"#).is_some());
        assert!(
            parse_event(
                r#"{"cwd":"/tmp/repo","hook_event_name":"UserPromptSubmit","prompt":"fix \u00e9"}"#
            )
            .is_some()
        );
        let event = parse_event(r#"{"nested":{"prompt":"wrong"},"cwd":"/tmp/repo","hook_event_name":"UserPromptSubmit","prompt":"fix \u00e9 and \ud83d\ude80"}"#).unwrap();
        assert_eq!(event.prompt, "fix é and 🚀");
        assert_eq!(event.cwd.to_str(), Some("/tmp/repo"));
        assert!(
            parse_event(r#"{"cwd":"/tmp/repo","hook_event_name":"Stop","prompt":"fix"}"#).is_none()
        );
        assert!(parse_event(r#"{"cwd":"/tmp/repo","hook_event_name":"UserPromptSubmit","prompt":"fix","prompt":"leak"}"#).is_none());
    }

    #[test]
    fn query_and_output_stay_bounded_and_encoded() {
        let query = search_query(&format!("{}🚀", "a".repeat(511)));
        assert_eq!(query.len(), 511);
        assert_eq!(
            json_string("one \"quote\"\nback\\slash"),
            "\"one \\\"quote\\\"\\nback\\\\slash\""
        );
    }
}
