<p align="center">
  <a href="https://r.uby.dev/mruby-llm/">
    <img
      src="rubydev.svg"
      width="400"
      height="200"
      border="0"
      alt="a r.uby.dev project"
     >
  </a>
</p>

> Changelog <br>
> a [r.uby.dev](https://r.uby.dev) project

## What's next

Changes since `v0.1.0`

None yet.

## v0.1.0

This release backports significant features from llm.rb to mruby-llm,
and relicenses the project under the Business Source License (BSL).

### Breaking

* **Relicense under Business Source License 1.1** <br>
  The mruby-llm project is relicensed from BSD Zero Clause (0BSD) to the
  Business Source License 1.1 (BUSL-1.1). Free use waivers are automatically
  granted for personal use, students and teachers, evaluation and development,
  non-profits, and companies with 50 or fewer employees. Each version converts
  to 0BSD four years after its first public release.

### Add

* **Add Symbol resolution to `LLM::Agent.tools` and `LLM::Agent.skills`** <br>
  The `tools` and `skills` DSL methods now accept a single Symbol argument,
  which is resolved to a method name on the agent instance at initialization
  time. This allows dynamic tool and skill lists, consistent with how `confirm`
  already works.

* **Add a new provider: LLM::DeepInfra** <br>
  [DeepInfra](https://deepinfra.com) provide OpenAI-compatible endpoints for a
  large catalog of open-source and open-weight models. Capabilities like tool
  calling, structured outputs, and reasoning can depend on the model.

* **Add `LLM::DeepInfra::Images`** <br>
  DeepInfra provides access to a diverse set of text-to-image models. Both
  `create` and `edit` methods are supported.

* **Add `LLM::DeepInfra::Audio`** <br>
  DeepInfra implements both `create_speech` and `create_transcription` methods.
  The `create_translation` method is not implemented.

* **Add `LLM::DeepSeek::Images`** <br>
  This new API can generate and edit vector graphics (SVGs) through DeepSeek's
  text-to-text models. It is an experimental approach that uses an
  `LLM::Agent` under the hood. Image responses expose that agent via
  `res.agent`, which makes it possible to carry the same session across
  multiple generations or edits.

* **Add `LLM::Schema.defaults`** <br>
  This method lets you map multiple property names to different default values,
  similar to how `LLM::Schema.required` works.

* **Add `LLM::Schema.to_s` and `LLM::Schema#to_s`** <br>
  Schemas can now be rendered as a prompt-friendly string, useful when the
  shape of a schema needs to be described in natural-language instructions.

* **DeepSeek: add `LLM::Schema` support** <br>
  DeepSeek can now use `schema:` for structured output. The runtime handles
  this by setting `response_format: {type: "json_object"}` and describing the
  schema in a system message.

* **Add `LLM::Tool::Shell`** <br>
  Add a built-in shell tool that can run a command with arguments.

* **Add `LLM::Tool::ReadFile`** <br>
  Add a built-in tool for reading the contents of a file, with optional
  `start` and `stop` line offsets.

* **Add `LLM::Tool::Chdir`** <br>
  Add a built-in tool for changing the current working directory.

* **Add `LLM::Tool::Git`** <br>
  Add a built-in tool that can perform git actions (log, diff, commit,
  checkout, branch, show).

* **Add `LLM::Tool::Rg`** <br>
  Add a built-in tool that wraps the `rg` (ripgrep) command for recursively
  searching the current directory for patterns.

* **Add `LLM::Tool::SwapText`** <br>
  Add a built-in tool that can replace an exact snippet of text in a file
  with a new piece of text.

* **Add `LLM::Tool::WriteFile`** <br>
  Add a built-in tool that can write content to a file.

* **Add `LLM::Tool::Mkdir`** <br>
  Add a built-in tool that can create a tree of new directories.

* **Add `LLM::Tool::Pwd`** <br>
  Add a built-in tool that returns the current working directory.

* **Add `LLM::Tool::Command`** <br>
  Add an internal command runner used by the shell, git, rg, and mkdir tools.

* **Add `LLM::URIData`** <br>
  Add a data URI parsing struct that provides `encoded`, `decoded`,
  `content_type`, and `encoding_type` accessors.

* **Add `LLM::Response#id` support for broader field lookup** <br>
  The `id` method now checks for `responseId`, `response_id`, `requestId`,
  and `request_id` in addition to the standard `id` field, making it work
  across more providers.

* **Add `#ask` to contexts and agents** <br>
  Add `LLM::Context#ask` and `LLM::Agent#ask` as a RubyLLM-compatible
  convenience interface. `#ask` accepts a prompt, optional stream target,
  and an optional block for streamed chunks.

* **Add `LLM.deepinfra` factory method** <br>
  Provide a top-level `LLM.deepinfra(key:)` shorthand for creating
  `LLM::DeepInfra` provider instances.

* **Update mruby-curl to v0.6.1** <br>
  Update the mruby-curl dependency from v0.6.0 to v0.6.1 and change the
  GitHub repository from `llmrb/mruby-curl` to `r-uby-dev/mruby-curl`.

* **Normalize OpenAI text-to-speech responses** <br>
  The `res.audio` method now returns an `LLM::URIData` object for OpenAI
  text-to-speech responses, providing `encoded`, `decoded`, `content_type`,
  and `encoding_type` accessors.

* **Rewrite README.md** <br>
  Complete rewrite of the README with new structure, updated feature
  descriptions, and application showcase table.

### Fix

* **Fix stream tool lookup** <br>
  Fix block parameter shadowing in `LLM::Stream#__find__` that could cause
  incorrect tool resolution during streaming.

## v0.1.0.beta.18

Changes since `v0.1.0.beta.17`.

This release improves the curl transport with connection timeout and
low-speed detection settings, and updates the mruby-curl dependency.

### Add

* **Add curl transport timeouts** <br>
  Set `connect_timeout`, `low_speed_limit`, and `low_speed_time` on the
  curl multi handle for better error detection on slow or stalled connections.
  Streaming requests now temporarily disable the overall curl timeout to
  prevent premature timeouts during long-running streams.

### Change

* **Update mruby-curl to v0.6.0** <br>
  Update the mruby-curl dependency from v0.5.0.beta.1 to v0.6.0.

## v0.1.0.beta.17

Changes since `v0.1.0.beta.16`.

This release fixes chunked transfer encoding handling in the curl transport
and updates project logos.

### Fix

* **Clear chunked encoding when necessary** <br>
  Fix the curl transport to properly handle chunked transfer encoding.

## v0.1.0.beta.16

Changes since `v0.1.0.beta.15`.

This release fixes string duplication in the stream parser.

### Fix

* **Duplicate strings in the stream parser** <br>
  Fix a stream parsing issue by duplicating strings in the parser to prevent
  mutation-related bugs.

## v0.1.0.beta.15

Changes since `v0.1.0.beta.14`.

This release updates the mruby-curl dependency.

### Change

* **Update mruby-curl to v0.5.0.beta** <br>
  Update the mruby-curl dependency to the latest beta.

## v0.1.0.beta.14

Changes since `v0.1.0.beta.13`.

This release refactors agent tool confirmation to support Symbol resolution
through instance methods.

### Add

* **Add Symbol resolution to `LLM::Agent.confirm`** <br>
  When `confirm` receives a single Symbol argument, it stores it as-is
  instead of converting it to a string array. At initialization time,
  `resolve_option` resolves the Symbol by calling the method with that
  name on the agent instance. This allows dynamic tool confirmation lists.

### Change

* **Refactor agent tool confirmation** <br>
  Extend the same Symbol resolution pattern used by `confirm` to other
  agent DSL attributes.

## v0.1.0.beta.13

Changes since `v0.1.0.beta.12`.

This release cleans up tool task internals.

### Change

* **Clean up tool task internals** <br>
  Refactor tool task execution for better maintainability.

## v0.1.0.beta.12

Changes since `v0.1.0.beta.11`.

This release inlines task helpers and improves the agent implementation.

### Change

* **Inline `LLM.task` and `LLM.task?`** <br>
  Move task helper methods inline for better compatibility with the
  mruby runtime.
