pub const RESULTS_MAX: usize = 3;
pub const CONTEXT_BYTES_MAX: usize = 2048;

pub fn rank(notes: &[String], query: &str) -> Vec<usize> {
    assert!(notes.len() <= 65536);
    assert!(query.len() <= 512);
    let mut terms = tokens(query);
    terms.sort();
    terms.dedup();
    terms.truncate(64);
    if terms.is_empty() {
        return Vec::new();
    }
    let mut document_counts = vec![0_u32; terms.len()];
    let mut documents = Vec::new();
    let mut length_total = 0_u32;
    for (id, note) in notes.iter().enumerate() {
        assert!(note.len() <= 512);
        if note.is_empty() {
            continue;
        }
        let words = tokens(note);
        let mut frequencies = vec![0_u16; terms.len()];
        for word in &words {
            if let Ok(index) = terms.binary_search(word) {
                frequencies[index] += 1;
            }
        }
        for (index, count) in frequencies.iter().enumerate() {
            if *count > 0 {
                document_counts[index] += 1;
            }
        }
        length_total += words.len() as u32;
        documents.push((id, words.len(), frequencies));
    }
    if length_total == 0 {
        return Vec::new();
    }
    let length_average = f64::from(length_total) / documents.len() as f64;
    let weights: Vec<f64> = document_counts
        .iter()
        .map(|count| {
            ((documents.len() as f64 - f64::from(*count) + 0.5) / (f64::from(*count) + 0.5)).ln_1p()
        })
        .collect();
    let mut scores = Vec::new();
    for (id, length, frequencies) in documents {
        let normalization = 1.2 * (0.25 + 0.75 * length as f64 / length_average);
        let score: f64 = frequencies
            .iter()
            .zip(&weights)
            .map(|(frequency, weight)| {
                let frequency = f64::from(*frequency);
                weight * frequency * 2.2 / (frequency + normalization)
            })
            .sum();
        if score > 0.0 {
            scores.push((id, score));
        }
    }
    scores.sort_by(|(left_id, left_score), (right_id, right_score)| {
        right_score
            .total_cmp(left_score)
            .then_with(|| right_id.cmp(left_id))
    });
    scores.into_iter().map(|(id, _)| id).collect()
}

pub fn within_budget(notes: &[String], ranking: &[usize]) -> Vec<usize> {
    assert!(notes.len() <= 65536);
    assert!(CONTEXT_BYTES_MAX >= 512 + 16);
    let mut selected = Vec::new();
    let mut bytes = 0;
    for id in ranking {
        assert!(*id < notes.len());
        let line_bytes = format!("#{id} {}\n", notes[*id]).len();
        if bytes + line_bytes > CONTEXT_BYTES_MAX {
            continue;
        }
        if notes[*id].is_empty() {
            continue;
        }
        bytes += line_bytes;
        selected.push(*id);
        if selected.len() == RESULTS_MAX {
            break;
        }
    }
    selected
}

fn tokens(text: &str) -> Vec<String> {
    assert!(text.len() <= 512);
    text.split(|character: char| !character.is_alphanumeric())
        .filter(|word| word.len() > 1)
        .map(str::to_lowercase)
        .filter(|word| {
            !matches!(
                word.as_str(),
                "an" | "and"
                    | "are"
                    | "as"
                    | "at"
                    | "be"
                    | "by"
                    | "can"
                    | "do"
                    | "for"
                    | "from"
                    | "how"
                    | "in"
                    | "is"
                    | "it"
                    | "of"
                    | "on"
                    | "or"
                    | "should"
                    | "that"
                    | "the"
                    | "this"
                    | "to"
                    | "we"
                    | "what"
                    | "when"
                    | "with"
            )
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::{rank, within_budget};

    #[test]
    fn rare_terms_rank_above_common_terms_and_erased_notes_stay_absent() {
        let notes = vec![
            "dashboard updates SSE keepalive".to_owned(),
            String::new(),
            "dashboard updates".to_owned(),
        ];
        assert_eq!(rank(&notes, "dashboard SSE"), vec![0, 2]);
        assert_eq!(rank(&notes, "quantum"), Vec::<usize>::new());
        assert_eq!(rank(&notes, "and the"), Vec::<usize>::new());
    }

    #[test]
    fn code_identifiers_and_cues_are_searchable_with_a_fixed_budget() {
        let mut notes = vec!["Set CGO_ENABLED=0; when: static binary fails".to_owned()];
        notes.extend((0..9).map(|_| "static binary fails".repeat(20)));
        assert_eq!(rank(&notes, "cgo enabled")[0], 0);
        assert_eq!(
            within_budget(&notes, &rank(&notes, "static binary fails")).len(),
            3
        );
        assert_eq!(within_budget(&notes, &[]).len(), 0);
    }
}
