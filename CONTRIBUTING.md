# Contributing to Kev Voice

Thanks for helping make local voice control more useful on the Mac.

## Run it locally

Follow the [build and setup instructions](README.md#quick-start). Before submitting a change, run:

```sh
bash build.sh
'dist/Kev Voice.app/Contents/MacOS/KevVoice' --self-test
'dist/Kev Voice.app/Contents/MacOS/KevVoice' --activity-test
```

The local suites use synthetic data and HTTP fixtures. A passing result does not replace a real-app check when changing action execution. Describe what you tested and distinguish recorded audio, typed commands, and physical-microphone tests.

## Decision backend changes

The decision backend is upstream Kev, served unmodified by `kev/vendor/kev`. The app speaks its System One API directly. If you change the client, the option catalogue, or the state format, re-run the accuracy harness with the server up:

```sh
bash kev/run.sh
'dist/Kev Voice.app/Contents/MacOS/KevVoice' --router-test --report /tmp/router.json
```

Report expected vs. selected actions and latency. Do not add hidden task heuristics to make cases pass; every action the app executes must come from the model's answer, validated against the criteria.

## Report a task that fails

Open an issue with the macOS and app version, the model run (`/v1/models` output), the target app, a non-sensitive example command, expected behavior, and what actually happened. Note whether the command was spoken or typed. Include only the relevant, redacted Kev activity excerpt; full traces can contain private screen text and URLs.

## Keep the decision loop general

Discover capabilities from the current interface and let the model choose. Avoid app-name rules, website aliases, task-specific macros, and hardcoded command recipes. Verify an action against fresh state before reporting success, and keep cancellation, server failures, and unavailable evidence visible.

Keep changes focused. Add a regression check for a behavior change where it meaningfully catches the failure, and explain any remaining live-test limits in the pull request.
