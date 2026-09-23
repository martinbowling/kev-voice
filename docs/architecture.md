# How Kev Voice works

[← Back to the README](../README.md)

## Observe, choose, act, verify

1. Apple on-device speech recognition accumulates the full spoken request.
2. The app preserves that request verbatim. It does not split it into scripted tasks.
3. It discovers installed applications and reads the current app's Accessibility tree: controls, menu items, windows, fields, values, and exposed actions.
4. It supplies these actions plus generic keyboard, scrolling, dragging, typing, waiting, and completion choices to the local Kev server.
5. Kev chooses one action. Parameter choices (text, complete key combinations, drag targets) are answered the same way.
6. The app executes that primitive and observes its result. The next decision includes completion alongside actions from the fresh catalogue, with the unchanged original request and history.
7. Kev selects completion. A separate decision compares the current screen against the entire request and its literal values before the app reports success.

There are no website aliases, app-specific task recipes, navigation macros, command-to-action regular expressions, or automatic completion after typing/launching. The capability catalogue does not take the request as an argument. The small fixed vocabulary is the execution machinery itself: physical keys, pointer events, Accessibility APIs, and voice session controls such as “cancel task.”

## The Kev decision server

The app POSTs to `POST /v1/systemone` on `127.0.0.1` (override with `KEV_CUA_URL`):

```json
{
  "model": "kev-latest",
  "state": {
    "original_request": "...",
    "current_screen": "...",
    "history_and_observations": "..."
  },
  "questions": {
    "next_action": {
      "type": "choice",
      "instructions": "...",
      "criteria": { "ax_button_12": "Click visible Coral button.", "...": "..." }
    }
  }
}
```

Kev answers:

```json
{
  "model": "kev-latest",
  "answers": {
    "next_action": {
      "type": "choice",
      "choice": "ax_button_12",
      "confidence": 0.52,
      "probabilities": { "ax_button_12": 0.52, "...": 0.48 }
    }
  },
  "usage": { "input_tokens": 0, "output_tokens": 0 },
  "latency_ms": 601.2
}
```

What the server is doing (`kev/serve.py`, upstream):

* **No generated text.** The state and each question are encoded into one token sequence. A pointer head scores every option's `</opt>` hidden state against the question's `<decide>` position, and a softmax turns those scores into probabilities. Option order can affect answers; questions cannot read each other.
* **States are rendered, not parsed.** Objects and arrays are converted to labelled text (`field: value`), which is why the app can send its state as a structured object.
* **Probabilities are calibrated** by a temperature fitted on Kev's development data; `KEV_TEMPERATURE=1.0` serves raw logits.
* **One checkpoint, one lock.** The server binds to loopback, caches state prefixes across requests (default 4), and answers any number of questions per request — the app usually sends one, or two for the completion audit.
* **Limits:** 1–255 options per Choice question; each question is scored in a row capped at 8,192 tokens (state + instructions + all options). A state longer than the window is truncated to it; a question whose options do not fit is rejected (HTTP 422), not truncated.

`GET /v1/models` returns the model card the app uses as a health check: `run`, `base`, `device`, `backend`, `dtype`, `temperature`, and prefix-cache stats.

## Why Kev and not a classifier

Both Jev and Kev are decision models: they output a typed choice rather than open-ended text. Kev implements the same System One contract the app was written against, so the execution loop needed no redesign — only the endpoint, model label, and error parsing changed.

A semantic classifier (for example a GLiNER2 label matcher, which this fork used briefly) also returns options and probabilities, but it scores text similarity. It cannot infer “already done”, follow ordering constraints, or reject a completion. Kev is trained on those decision shapes, which is what the comparison in the README measures.

## Options and typing

Every discovered option is retained. The 255-choice limit is handled by groups: compact action labels select a group; full descriptions select the action. Generic operations remain directly selectable. Large catalogues route through operation categories and alphabetical target groups. Only the selected branch is evaluated, avoiding exhaustive parallel nominations. Every discovered leaf remains reachable. Category and group selection execute nothing; UI actions remain sequential. Accessibility scans have a time/node budget and explicitly report incomplete scans; Kev can request a deeper scan.

Typing is also selection. Insertion and whole-field replacement are separate choices. Replacement selects all text, verifies that selection, pastes the chosen literal, and verifies the resulting field value; it never submits automatically. Kev selects a source (your request or observed text), the first token, then the complete substring to insert. Code preserves its spelling, punctuation and internal whitespace. Typing does not switch apps, focus another field, submit, navigate, or silently add a domain. “Open YouTube” can therefore lead to entering “YouTube” in a browser and following a search result. A website mapping does not supply “youtube.com.”

## Limits

Kev cannot generate new prose or understand screenshots. Original writing, custom-drawn/inaccessible controls, arbitrary pixel-level editing and unrestricted human-equivalent operation are **not** supported. Some UI trees provide incomplete or stale information. This app is a general Accessibility-based action picker, not a guarantee that every task will succeed. Secure fields are excluded. Pointer targets are checked; uncertain text insertion stops to prevent duplication. The completion check reduces false success but is not infallible.
