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

This release backports the llm.rb concurrency overhaul, the
`LLM::Guard` / `LLM::Transformer` / `LLM::Compactor` class hierarchies,
the `LLM::Agent` and tooling DSLs, and a wide range of API additions
and fixes that bring mruby-llm up to parity with llm.rb v14.0.0.

### Breaking

* **Rename `Context#functions` to `pending_functions`** <br>
  `LLM::Context#functions` and `#functions?` are renamed to
  `pending_functions` / `pending_functions?` to match llm.rb. The old
  names are removed; `LLM::Message#functions` is unchanged.

* **Rename the `:call` strategy to `:sequential`** <br>
  The `:call` execution strategy is renamed to `:sequential`, and
  `Function#spawn` / `Array#spawn` are superseded by
  `Function#task(strategy)` / `Array#task(strategy)`, which build
  strategy tasks and groups for `:sequential`, `:task`, and `:fork`.
  The old `spawn` methods remain as deprecated aliases.

* **Replace the transformer interface** <br>
  The `transformer=` setter and 3-argument `call(ctx, prompt, params)`
  interface are replaced by the `LLM::Transformer` class hierarchy.
  Configure a transformer class through `transformer:` and options
  through `transformer_options:`.

* **Replace the compactor interface** <br>
  The single-class `LLM::Compactor` (LLM-based summarization) is
  replaced by the `LLM::Compactor::Truncate` / `Compactor::Null`
  strategies. Configure a compactor class through `compactor:` and
  options through `compactor_options:`.

* **Replace `LLM::LoopGuard` with the `LLM::Guard` class hierarchy** <br>
  `LLM::Guard` is a new superclass for context-level supervisors, with
  `LLM::Guard::Loop` (replacing `LLM::LoopGuard`) and `LLM::Guard::Null`
  as the built-in implementations. Guards now intercept individual tool
  calls: `call(function:)` returns an `LLM::Function::Return` (or nil)
  instead of a warning string for the whole batch. `LLM::Agent` enables
  `LLM::Guard::Loop` by default.

* **Rename `Function#rate_limit` to `Function#budget_spent`** <br>
  The in-band type changes to `"LLM::BudgetSpentError"`, and
  `LLM::ToolLoopError` is dropped from `error.rb`.

* **Rename `LLM::Tool::SwapText` to `LLM::Tool::EditFile`** <br>
  The tool class is renamed to match llm.rb; the old name is removed.

* **Drop `LLM::GuardError`** <br>
  The constant was never raised as an exception; guarded tool returns
  now use the string `"guard_error"` as their error type.

* **Rename `usage` to `token_usage` across contexts, agents, and messages** <br>
  `LLM::Context#usage`, `LLM::Agent#usage`, and `LLM::Message#usage` are
  now aliases of `token_usage`. `LLM::Message#token_usage` returns a copy
  of `LLM::Usage` instead of `LLM::Object`, and only returns a value for
  assistant messages.

* **`LLM::Context#context_window` returns `nil` when unknown** <br>
  `LLM::Context#context_window` now returns `nil` when the model's
  context window size is not known to the runtime, instead of `0`. This
  makes the code check for a window instead of a number, so an unknown
  window no longer reads as a real (zero) size.

### Add

* **Add the llm.rb concurrency model** <br>
  Tool execution is rebuilt around two abstract base classes —
  `LLM::Function::Task` and `LLM::Function::Group` — with lazy
  `spawn`/`wait` separation, a `group_class` contract, and three
  strategies: `:sequential` (direct calls), `:task` (cooperative
  scheduling through mruby-task), and `:fork` (child processes).
  `Array#wait(strategy)` returns the waited values, and
  `LLM::Stream::Queue#wait` groups queued work by `group_class`. This
  fixes two latent defects: `:task` waits from the root task no longer
  raise `"join can only be called from running task"`, and
  `Array#wait` no longer returns the group instead of the values.

* **Add the `LLM::Guard` class hierarchy** <br>
  `LLM::Guard` / `Guard::Null` / `Guard::Loop` with per-function
  interception. `LLM::Function` gains `guard` and `return`; the guard is
  stamped on functions by `Context#pending_functions` and every stream
  parser, and each strategy task short-circuits on a guarded result
  without running the tool.

* **Add `LLM::Transformer`** <br>
  `LLM::Transformer` / `Transformer::Null` rewrite the most recent
  message before it is sent to the provider. `Context#transform` builds
  messages through `Provider#build_messages` and fires single-argument
  `on_transform` / `on_transform_finish` stream callbacks.

* **Add `LLM::Provider#build_messages`** <br>
  A single idempotent message builder that normalizes a prompt into
  `LLM::Message` objects and prepends history, replacing the five
  per-provider `build_complete_messages` implementations.

* **Add the `LLM::Compactor` strategies** <br>
  `LLM::Compactor::Truncate` drops the oldest messages (with a `keep:`
  count or percentage), and `Compactor::Null` is the no-op default.
  Stream callbacks are single-argument.

* **Add bulk-assignment DSLs** <br>
  `LLM::Tool.set`, `LLM::Tool::Param#defaults`, and `LLM::Agent.set`
  let classes assign multiple name/description/parameter/option values
  in one call.

* **Add `LLM::Agent` class attributes** <br>
  `Agent.name`, `Agent.description`, and `Agent.path` (with automatic
  session persistence when `path` is set), plus `Agent#compacted?`
  delegating to the wrapped context.

* **Add `LLM::Tracer::PrettyLogger`** <br>
  A human-readable, single-line request and tool-call logger to
  `$stderr` (or an `io:` option).

* **Add built-in tools** <br>
  `LLM::Tool::Ls` (directory listing with glob patterns, shelling out to
  `find`), `LLM::Tool::Which` (command lookup on PATH), and
  `LLM::Tool::EditFile` (renamed from `SwapText`).

* **Extend skills** <br>
  `LLM::Skill.load` accepts a file path in addition to a directory, and
  the frontmatter `tools:` key accepts `all` / `"*"` to load the full
  tool registry.

* **Extend `LLM::Buffer`** <br>
  Add the array-like methods `first`, `reject!` (alias `delete_if`),
  `select!`, `shift`, `clear`, `drop`, `take`, `slice!`, `reverse`, and
  `pop`.

* **Add small API surface from llm.rb** <br>
  `LLM::Function#return` and `LLM::Function#def`, `LLM::File#exist?`,
  `LLM::MCP#session` (alias of `#run`), `LLM::NotFoundError` (raised by
  provider error handlers on HTTP 404), and `LLM::Schema::Leaf#index`
  for property ordering.

* **Add `LLM::Agent.tool_budget` and `LLM::Function#budget_spent`** <br>
  Replace the `tool_attempts` run-loop parameter (default 25) with the
  `Agent.tool_budget` class DSL (default `nil`, disabled) and rename
  `Function#rate_limit` to `Function#budget_spent`. Once the budget is
  spent, the agent sends an in-band advisory message
  (`"LLM::BudgetSpentError"`) back through the model and keeps the loop
  in-band.

* **Expand `LLM::Cost` and `LLM::Usage`** <br>
  `Cost` grows from 2 to 8 fields (input/output, input/output audio,
  input image, cache read/write, reasoning) with pretty aliases
  (`input`, `output`, `input_audio`, `output_audio`, `input_image`,
  `cache_read`, `cache_write`, `reasoning`), a `Cost.from(ctx)` builder
  that prices token usage from the registry, and a `to_h` that omits nil
  components. `Usage` grows from 4 to 9 token fields. The OpenAI
  (completions + responses), Anthropic, Google, and Ollama response
  adapters now report audio/image/cache token usage.

* **Add a new provider: LLM::Moonshot** <br>
  [Moonshot AI](https://platform.moonshot.ai) through its
  OpenAI-compatible Kimi API (`LLM.moonshot(key:)`, default model
  `kimi-k3`), plus `data/moonshot.json` registry data.

* **Sync the registry data and add `data/deepinfra.json`** <br>
  All `data/*.json` files are synced with llm.rb's registry data, and the
  missing `data/deepinfra.json` is added — fixing a latent
  `LLM::NoSuchRegistryError` for `ctx.cost` on DeepInfra. The DeepInfra
  and Mistral default models were updated to match llm.rb.

* **Add a new provider: LLM::Alibaba** <br>
  [Alibaba Cloud Model Studio](https://www.alibabacloud.com/help/en/model-studio/models)
  through its OpenAI-compatible API (`LLM.alibaba(key:)`, aliased as
  `LLM.aliyun`). The default host is the pay-as-you-go endpoint
  (`dashscope-intl.aliyuncs.com/compatible-mode/v1`) — override it
  globally with the `ALIBABA_API_HOST` environment variable or per
  instance with `LLM.alibaba(host: ...)`, for example to point at a
  Token Plan endpoint — with default model `deepseek-v4-flash-0731`,
  plus `data/alibaba.json` registry data. Alibaba does not support
  `json_schema`, so schema handling falls back to `json_object` with an
  injected system message — the shared `LLM::OpenAI::Schema` module,
  which is also factored out of DeepSeek.

* **Add `retry_budget` support** <br>
  `LLM::Context` accepts `retry_budget:` (default 0) and retries
  `LLM::RateLimitError` with a growing sleep (2s, 4s, ...), notifying
  `Stream#on_rate_limit` before each retry. `LLM::Agent.retry_budget` is a
  class DSL that enables a budget of 3 by default.

* **Add `LLM::Usage.zero`** <br>
  `LLM::Context#usage` and `LLM::Agent#usage` now return `LLM::Usage`
  objects instead of `LLM::Object` when no provider usage has been
  recorded.

* **Sync the DeepInfra registry data** <br>
  `data/deepinfra.json` is refreshed with llm.rb's latest pricing for
  `MiniMaxAI/MiniMax-M3`, `deepseek-ai/DeepSeek-V4-Flash-0731`,
  `moonshotai/Kimi-K2.7-Code`, `moonshotai/Kimi-K3`, and
  `thinkingmachines/Inkling-Small`.

* **Add `LLM::Registry::Model` and `Registry#keys` / `#models` / `#env`** <br>
  `LLM::Registry` now exposes the model names through `#keys` and wraps
  every registry entry in a `LLM::Registry::Model` value object through
  `#models`. Models are `Comparable` by price (input cost first, then
  output cost, with unpriced models sorting last) and carry the metadata
  predicates `tool_call?`, `reasoning?`, `structured_output?`,
  `open_weights?`, and `text?`, plus the modality queries `input?` /
  `output?` (`image?`, `audio?`, `pdf?`, `video?`). `#env` returns the
  provider's environment variable names.

* **Discover API keys from the environment** <br>
  The cloud provider factories (`LLM.anthropic`, `LLM.google`,
  `LLM.deepseek`, `LLM.openai`, `LLM.xai`, `LLM.mistral`, `LLM.zai`,
  `LLM.moonshot`, `LLM.alibaba`, and `LLM.aliyun`) now resolve the
  provider's API key automatically when no `key:` is given, by walking
  the environment variable names listed in the models.dev registry. So
  `LLM.openai` works without an explicit key as long as `OPENAI_API_KEY`
  (or one of the registry's alternative names) is set in the
  environment. A missing key raises `ArgumentError`. The local providers
  (`ollama`, `llamacpp`) keep a `nil` key.

* **Add `LLM::Provider#registry`** <br>
  `LLM::Provider#registry` returns the provider's model registry, and
  `LLM::Context#registry` / `LLM::Agent#registry` now delegate to their
  underlying provider instead of looking it up on their own.

* **Aggregate token usage across all assistant messages** <br>
  `LLM::Context#token_usage` (alias `usage`) now sums token usage across
  every assistant message in the conversation instead of returning only
  the first message's usage. `LLM::Usage` is now a plain class with
  `from`, `+`, and `==` and zero-filled accessors, so usages can be
  added, copied, and compared.

* **Add `LLM::Context#context_used` and `LLM::Agent#context_used`** <br>
  Return the live context size (in tokens) of the most recent assistant
  message, or `nil` when no assistant message has a recorded token usage.
  This fills the gap left after `token_usage` became accumulative and no
  longer represented a single turn.

* **Add `LLM::Context#context_usage` and `LLM::Agent#context_usage`** <br>
  Return the fraction of the model's context window currently used as a
  `Rational` (for example `Rational(100, 10_000)`), or `nil` when the
  used amount or the window size is unknown.

### Change

* **Shell out for glob matching in `LLM::Tool::Ls`** <br>
  The hand-rolled glob engine is replaced by a `find` shell-out, and all
  command-based tools (`Shell`, `Rg`, `Git`, `Mkdir`, `Ls`) now resolve
  the `mruby-command` gem's `Command` class directly — previously they
  referenced a `LLM::Tool::Command` constant that never existed and
  raised `NameError` when invoked.

* **Do not mutate caller params in constructors** <br>
  `LLM::Context#initialize` and `LLM::Agent#initialize` copy `params`
  before deleting keys, so the caller's hash is no longer modified.

### Fix

* **Fix `:task` waits from the root task** <br>
  `LLM::Function::Task::Task#wait` no longer calls `Task#join` (which
  raises from the root task); it polls the result queue non-blockingly.
  A second wait on the same task returns the same result instead of the
  worker's queue object.

* **Fix large fork results being dropped** <br>
  The fork child's non-blocking write now retries `Chan::WaitWritable`,
  so tool results larger than the pipe buffer survive.

* **Fix interrupts being traced as errors** <br>
  `LLM::Function::Tracing#call` and `call_function` re-raise
  `LLM::Interrupt` before the generic rescue, so interrupted tool calls
  propagate instead of being reported as `tool.error` events.

* **Fix `LLM::Object#fetch` KeyError messages** <br>
  A missing key now reports the original key name instead of `nil`.

* **Fix OpenAI-subclass host forwarding** <br>
  DeepInfra and Mistral used a bare `super` in their initializers, which
  mruby does not forward kwargs through — requests were sent to
  `api.openai.com` instead of the provider's own host. Both now forward
  `host:`/`base_path:` explicitly (`api.deepinfra.com`, `api.mistral.ai`).

* **Fix OpenAI streamed-usage reporting** <br>
  `normalize_complete_params` now resolves the stream through
  `LLM::Stream.try` and checks `enabled?`, so `stream_options:
  {include_usage: true}` is only sent for genuinely streaming requests.
  A disabled stream (`false` / `LLM::Stream::Disabled`) is no longer marked
  as streaming, and the transport layer treats it exactly like `false`.

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
