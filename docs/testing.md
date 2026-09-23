# Tests and diagnostics

[← Back to the README](../README.md)

Run the local checks without a model server or UI actions:

```sh
'dist/Kev Voice.app/Contents/MacOS/KevVoice' --self-test
'dist/Kev Voice.app/Contents/MacOS/KevVoice' --activity-test
```

The commands below use the same executable in `dist/Kev Voice.app/Contents/MacOS/`:

- `KevVoice --activity-test`: real-client HTTP fixtures for response validation, cancellation, timeouts, automatic recovery, rejected-request handling, and a 4,000-option bounded routing regression.
- `KevVoice --self-test`: catalogue retention, literal span integrity, keyboard coverage, speech buffering, continuous queue checks, Kev endpoint/model identity, and server error parsing (`error.message` and `detail`).
- `KevVoice --router-test --report /absolute/path/report.json`: sends the synthetic selection cases to the running Kev server. No UI actions, no network beyond `127.0.0.1`. The report lists every expected and selected action with latency, and is the accuracy harness for comparing checkpoints (Kev-0.8B / 4B / 9B, or your own fine-tunes). Baseline results and per-case failure rates for Kev-4B and Kev-9B are recorded in [`benchmarks/`](benchmarks/README.md); identical requests can flip between runs, so compare several runs rather than one.
- `open 'dist/Kev Voice.app' --args --diagnostics`: start with Settings, the command bar and mic off. Use Back to bar to close Settings.
- In diagnostics, typing into the command bar uses the same production action loop. Each run writes `kev-voice-picker-last-run.json` beside the app, including original request, every choice catalogue, decision inputs/outputs, executed actions and observations. It contains screen text; ordinary launch does not persist these traces.
- Settings → General → Voice diagnostics → Replay audio command accepts a local recording through the real continuous speech engine and command queue. This is a recorded-audio test, not a physical microphone test. Recordings are not included in this repository; supply your own audio fixture to test continuous recognition and execution. Requests are preserved literally; absent apps are no longer silently substituted.

GitHub Actions builds the app on a macOS ARM64 runner, verifies its signature, and runs the two local suites. The workflow uses ad-hoc signing, no credentials, and no model download. See [GitHub runner specifications](https://docs.github.com/en/actions/reference/runners/github-hosted-runners).

The self-test and activity-test suites check code and HTTP handling. They do not measure model accuracy. The router test needs `kev/run.sh` running and measures the checkpoint against the app's synthetic decision suite; use it before and after changing the client, the catalogue, or the checkpoint. Recorded-audio execution and normal commands can act on your Mac.
