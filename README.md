<p align="center">
  <a href="https://r.uby.dev/mruby-llm/">
    <img src="rubydev.svg" width="400" height="200" border="0" alt="a r.uby.dev project">
  </a>
</p>

> A [r.uby.dev](https://r.uby.dev/mruby-llm) project.

Welcome to the canonical mruby-llm repository.

mruby-llm is an advanced runtime for building agentic AI applications
on mruby. It has zero runtime dependencies by default, it supports
concurrent and parallel tool execution and has a single coherent API
that spans 12+ providers. Streaming, tools, guards, compaction, builtin
MCP/A2A support all build on the same three concepts: providers,
contexts, and agents.

Once you learn the fundamentals, everything else falls into place
naturally. mruby-llm is a port of [llm.rb](https://github.com/r-uby-dev/llm)
from CRuby to mruby and certain features - such as ActiveRecord support -
are absent from the mruby runtime. The concurrency model is almost
the same but the available strategies are limited to what mruby and
its ecosystem provide.

## Install

Source code and build instructions are available from
[github.com/r-uby-dev/mruby-llm](https://github.com/r-uby-dev/mruby-llm).

```ruby
MRuby::Build.new("app") do |conf|
  conf.gembox "default"
  conf.gem github: "r-uby-dev/mruby-llm", branch: "main"
end
```

## Quick start

### Agents

The
[`LLM::Agent`](https://r.uby.dev/api-docs/llm.rb/LLM/Agent.html)
class is the default high-level interface,
and it is recommended for most use-cases. It manages tool execution
automatically and
guards against infinite loops,
manages conversation state, and much more.

```ruby
llm = LLM.deepseek(key: ENV["KEY"])
agent = LLM::Agent.new(llm, stream: $stdout)
agent.talk "hello world"
```
<details>
<summary>Stream</summary>
<br>

Streams can be simple IO objects or subclasses of
[`LLM::Stream`](https://r.uby.dev/api-docs/llm.rb/LLM/Stream.html)
with structured callbacks for content,
reasoning, tool calls, tool returns, and compaction.
Streams can also observe message transformers, which rewrite
outgoing messages before they reach the provider.

```ruby
class MyStream < LLM::Stream
  # Visible assistant output.
  def on_content(content)
    print content
  end

  # Reasoning output streamed separately from visible content.
  def on_reasoning_content(content)
    warn content
  end

  # A streamed tool call has been fully parsed.
  def on_tool_call(tool, error)
  end

  # Queued streamed tool work has returned.
  def on_tool_return(tool, result)
  end

  # Before and after a transformer rewrites an outgoing message.
  def on_transform(transformer)
  end

  def on_transform_finish(transformer)
  end

  # Before and after a compactor trims the conversation.
  def on_compaction(compactor)
  end

  def on_compaction_finish(compactor)
  end

  # A request was rate limited and will be retried.
  def on_rate_limit(error)
  end
end

llm = LLM.deepseek(key: ENV["KEY"])
agent = LLM::Agent.new(llm, stream: MyStream.new)
agent.talk "Explain Ruby fibers."
```
</details>

<details><summary>Tools</summary>
<br>

Subclasses of
[`LLM::Tool`](https://r.uby.dev/api-docs/llm.rb/LLM/Tool.html)
are plain Ruby classes with
an optional set of typed parameters. <br> The model can choose to
call them on your behalf, and they're one of the most powerful features
for extending the feature set or abilities of a model.

The runtime also ships with a catalog of built-in tools for
filesystem, search, and shell operations.

```ruby
class ReadFile < LLM::Tool
  name "read-file"
  description "Read a file"
  parameter :path, String, "The filename or path"
  required %i[path]

  def call(path:)
    {contents: File.read(path)}
  end
end

llm = LLM.deepseek(key: ENV["KEY"])
agent = LLM::Agent.new(llm, tools: [ReadFile], stream: $stdout)
agent.talk "summarize README.md"
```
</details>
<details>
<summary>Skills</summary>
<br>

A skill turns a markdown file into a callable tool. When the model
calls it, the runtime spawns a subagent with the skill's instructions
as its system prompt and the skill's own tool set. The subagent runs
one turn and returns the result, then is discarded. Each call
is fresh and stateless.

##### SKILL.md

```markdown
---
name: summary
description: Reads recent git history and writes a summary
tools: all
---

Collect the recent git log, analyze each commit,
and write a summary to summary.txt.
```

##### agent.rb

```ruby
llm   = LLM.deepseek(key: ENV["KEY"])
agent = LLM::Agent.new(llm, skills: ["./skills/summary"])
agent.talk "Summarize the last week of work"
```
</details>

<details>
<summary>Concurrency</summary>
<br>

The runtime supports three different concurrency strategies that have
different attributes. The choice between them often depends on the
requirements of your application and the mruby build you ship.

The `:sequential` strategy runs tools one at a time and is the default.
The `:task` strategy is lightweight concurrent execution through
mruby-task. The `:fork` strategy provides a separate process that offers
isolation from its parent, where the target platform supports it.

```ruby
llm   = LLM.deepseek(key: ENV["KEY"])
tools = LLM::Tool.registry
agent = LLM::Agent.new(llm, tools:, concurrency: :fork)
agent.talk "Run the tools in parallel"
```

</details>
<details>
<summary>Cancellation</summary>
<br>

Abort a request mid-stream and interrupt any running tools with
[`LLM::Agent#interrupt!`](https://r.uby.dev/api-docs/llm.rb/LLM/Agent.html#interrupt!)
(or `cancel!`), from any task. The runtime raises
[`LLM::Interrupt`](https://r.uby.dev/api-docs/llm.rb/LLM/Interrupt.html)
on the caller and on every active tool. A forked tool gets interrupted
over the control channel, and pending tools are stopped before they
run. The in-flight HTTP request is closed too, so a turn you no longer
want stops without burning tokens.

```ruby
llm = LLM.deepseek(key: ENV["KEY"])
agent = LLM::Agent.new(llm)

Task.new do
  sleep 1
  agent.cancel!
end

begin
  agent.talk "write a very long poem", stream: $stdout
rescue LLM::Interrupt
  puts "cancelled"
end
```
</details>
<details>
<summary>Persistence</summary>
<br>

Set `path:` on an agent for automatic filesystem persistence:
the agent restores conversation history from the file on startup
and saves it back after every turn, with no manual serialization
code. All persistence options use the same underlying serialization.

```ruby
llm = LLM.deepseek(key: ENV["KEY"])
agent = LLM::Agent.new(llm, path: "session.json")
agent.talk "remember my name is robert"

# Next time, the conversation is restored automatically:
agent = LLM::Agent.new(llm, path: "session.json")
agent.talk "what's my name?"
```
</details>

<details><summary>Structured outputs</summary>
<br>

[`LLM::Schema`](https://r.uby.dev/api-docs/llm.rb/LLM/Schema.html)
subclasses produce typed, structured
output from any model call. Pass a schema to
[`LLM::Context#talk`](https://r.uby.dev/api-docs/llm.rb/LLM/Context.html#talk-instance_method),
[`LLM::Agent#talk`](https://r.uby.dev/api-docs/llm.rb/LLM/Agent.html#talk-instance_method),
or
[`LLM::Provider#complete`](https://r.uby.dev/api-docs/llm.rb/LLM/Provider.html#complete-instance_method)
to receive validated JSON instead of free text. Schemas work alongside tools and streams.

[`LLM::Schema`](https://r.uby.dev/api-docs/llm.rb/LLM/Schema.html)
can define objects, arrays, enums, nested schemas,
and more. It is also used internally by
[`LLM::Tool`](https://r.uby.dev/api-docs/llm.rb/LLM/Tool.html) for parameter
definitions, so you already benefit from it when you declare tool
parameters.

The
[`LLM::DeepSeek`](https://r.uby.dev/api-docs/llm.rb/LLM/DeepSeek.html)
provider includes runtime-level optimisations such as structured
output support (despite no official structured outputs API) and
SVG image generation. This example uses
[`LLM::Schema`](https://r.uby.dev/api-docs/llm.rb/LLM/Schema.html) with
DeepSeek:

```ruby
class Weather < LLM::Schema
  property :city, String, "The city name"
  property :temperature, Number, "Current temperature"
  property :conditions, String, "Weather conditions"
  required %i[city temperature conditions]
end

llm = LLM.deepseek(key: ENV["KEY"])
agent = LLM::Agent.new(llm, schema: Weather)
res = agent.talk "Weather in Paris?"
res.content!  # => {city: "Paris", temperature: 15.0, conditions: "Cloudy"}
```
</details>
<details><summary>Guards</summary>
<br>

[`LLM::Guard`](https://r.uby.dev/api-docs/llm.rb/LLM/Guard.html)
is the hook that sees every tool call before it runs. A guard
can let a call through, cancel it, block it with an error, or
even answer for it. Because it runs before the tool, anything
it intercepts never executes. Policy, validation, quotas, and
cost ceilings all live here.

[`LLM::Agent`](https://r.uby.dev/api-docs/llm.rb/LLM/Agent.html)
enables
[`LLM::Guard::Loop`](https://r.uby.dev/api-docs/llm.rb/LLM/Guard/Loop.html)
by default, so agents get loop protection out of the box. To
write your own guard, subclass
[`LLM::Guard`](https://r.uby.dev/api-docs/llm.rb/LLM/Guard.html)
and implement
[`LLM::Guard#call`](https://r.uby.dev/api-docs/llm.rb/LLM/Guard.html#call-instance_method).
The pending call arrives as `function:`. Return a value to close
the call, or `nil` to let it run:

```ruby
class PolicyGuard < LLM::Guard
  def call(function:)
    if function.name == "shell"
      function.return(error: true, type: "policy_error",
                      message: "shell is disabled")
    end
  end
end

llm = LLM.deepseek(key: ENV["KEY"])
agent = LLM::Agent.new(llm, tools: [Shell], guard: PolicyGuard)
```
</details>

<details>
<summary>Transformers</summary>
<br>

It is possible to rewrite outgoing messages before they reach the provider with
[`LLM::Transformer`](https://r.uby.dev/api-docs/llm.rb/LLM/Transformer.html).
Create a subclass and implement `call(message:)` to scrub sensitive data,
inject context, or normalize content. The transform runs automatically
on every turn, so you never have to change your prompt code.

```ruby
class RedactEmails < LLM::Transformer
  def call(message:)
    content = message.content.to_s.gsub(/[\w.+-]+@[\w-]+\.[\w.]+/, "[EMAIL]")
    LLM::Message.new(message.role, content, message.extra)
  end
end

llm = LLM.deepseek(key: ENV["KEY"])
agent = LLM::Agent.new(llm, transformer: RedactEmails)
agent.talk "Contact support@example.com for help"
```
</details>

<details>
<summary>Compactors</summary>
<br>

Every model has a context window: the finite number of tokens it can
consider in a single request. Generally a compactor will drop or
summarize older messages to keep the conversation within that window,
and it runs automatically before every turn. By default it is disabled
so it is a feature you must opt into.

[`LLM::Compactor::Truncate`](https://r.uby.dev/api-docs/llm.rb/LLM/Compactor/Truncate.html)
keeps the most recent messages via an integer count or a percentage like
`"80%"`. It preserves tool call and return pairs so the conversation
never contains an orphaned result. It is also possible to subclass
[`LLM::Compactor`](https://r.uby.dev/api-docs/llm.rb/LLM/Compactor.html)
to implement your own compactor with its own logic. Streams can observe the
process through the
[`LLM::Stream#on_compaction`](https://r.uby.dev/api-docs/llm.rb/LLM/Stream.html#on_compaction)
and
[`LLM::Stream#on_compaction_finish`](https://r.uby.dev/api-docs/llm.rb/LLM/Stream.html#on_compaction_finish)
callbacks.

```ruby
llm = LLM.deepseek(key: ENV["KEY"])
agent = LLM::Agent.new(
  llm,
  compactor: LLM::Compactor::Truncate,
  compactor_options: {keep: 64}
)
agent.talk "Hello"
```
</details>

<details>
<summary>Automatic retries</summary>
<br>

Rate-limited requests are retried automatically by default. Agents
retry a 429 up to five times with a growing backoff before giving
up, so most request failures resolve on their own. Set `retry_budget`
to change the number of retries, or `retry_budget: 0` to disable
them.

```ruby
llm = LLM.deepseek(key: ENV["KEY"])
agent = LLM::Agent.new(llm, retry_budget: 0)
agent.talk "Hello"
```

</details>


<details>
<summary>Observability</summary>
<br>

Trace what an agent is doing by attaching a tracer. Hook into
requests, tool calls, and other runtime events to debug a
misbehaving agent, monitor latency, or export spans to an
observability backend. All built-in tracers share one interface,
so switching between them means changing a class name:

* [`LLM::Tracer::PrettyLogger`](https://r.uby.dev/api-docs/llm.rb/LLM/Tracer/PrettyLogger.html): human-readable single-line logs to stderr, ideal during development.
* [`LLM::Tracer::Logger`](https://r.uby.dev/api-docs/llm.rb/LLM/Tracer/Logger.html):
structured JSON to stdout or a file.

```ruby
llm = LLM.deepseek(key: ENV["KEY"])
agent = LLM::Agent.new(llm, tracer: LLM::Tracer::PrettyLogger.new(llm))
agent.talk "Hello"
```
</details>

<details>
<summary>As a subclass</summary>
<br>

[`LLM::Agent.set`](https://r.uby.dev/api-docs/llm.rb/LLM/Agent.html#set-class_method)
is a class-level DSL that accepts a Hash of properties. Each key resolves to a
corresponding class accessor: `name`, `description`, `model`, `tools`,
`instructions`, `schema`, `stream`, `tracer`, `concurrency`, `confirm`,
`path`, `skills`, `tool_budget`, and `retry_budget`. All options are
optional; zero or more can be set.
An error is raised for unknown keys so that typos are caught early.

```ruby
class Agent < LLM::Agent
  set name: "sysadmin",
      description: "system administration agent",
      model: "deepseek-v4-pro",
      tools: [LLM::Tool::Shell]
end

llm = LLM.deepseek(key: ENV["KEY"])
agent = Agent.new(llm)
agent.talk "Run 'date'"
```
</details>

### Providers

Each provider is constructed with a class-level factory method on
`LLM`, and the resulting instance is passed to
[`LLM::Context`](https://r.uby.dev/api-docs/llm.rb/LLM/Context.html)
or
[`LLM::Agent`](https://r.uby.dev/api-docs/llm.rb/LLM/Agent.html). The
same API also drives Google Gemini, DeepInfra, xAI, Z.ai, Moonshot,
Alibaba, Mistral, Ollama, and llama.cpp.

<details>
<summary>Implicit</summary>
<br>

Cloud providers can infer their API key automatically
from a set of common defaults that are defined by
the [models.dev](https://models.dev) registry that
is also distributed with mruby-llm.

```ruby
llm = LLM.openai
llm = LLM.anthropic
llm = LLM.deepseek
llm = LLM.alibaba  # also: LLM.aliyun
llm = LLM.moonshot
llm = LLM.mistral
```
</details>
<details>
<summary>Explicit</summary>
<br>

The `key` option can also be provided explicitly, and certain
providers (eg ollama, llamacpp) usually do not require an API
key at all.

```ruby
llm = LLM.openai(key: ENV["OPENAI_API_KEY"])
llm = LLM.anthropic(key: ENV["ANTHROPIC_API_KEY"])
llm = LLM.deepseek(key: ENV["DEEPSEEK_API_KEY"])
llm = LLM.alibaba(key: ENV["DASHSCOPE_API_KEY"]) # also: LLM.aliyun
llm = LLM.moonshot(key: ENV["MOONSHOT_API_KEY"])
llm = LLM.mistral(key: ENV["MISTRAL_API_KEY"])
```
</details>

<details>
<summary>Model Registry</summary>
<br>

Each provider ships its model catalog, pricing, limits, and
modalities with the gem, sourced from [models.dev](https://models.dev).
Reach it from any provider, context, or agent, enumerate models, or
sort them by price.

```ruby
llm      = LLM.openai
registry = llm.registry                # => LLM::Provider#registry
cheapest = registry.models.sort.first  # => LLM::Model
cheapest.id                            # => "text-embedding-3-small"
cheapest.context_window                # => 8191
cheapest.structured_output?            # => false
```
</details>

<details>
<summary>Transports</summary>
<br>

The `transport:` option selects which HTTP implementation a provider
uses for network communication. mruby-llm ships a single curl-based
transport that is always available and is the default, so most
applications need no configuration at all.

```ruby
llm = LLM.deepseek(
  key: ENV["KEY"],
  transport: LLM::Transport::Curl.new(
    host: "api.deepseek.com", port: 443, timeout: 180, ssl: true
  )
)
```
</details>

### RAG

Most providers offer an embedding model that can be
used for semantic search, or similarity search. An
embedding model can generate embeddings that can then
be stored in a database that is optimized for storing
and querying vectors, such as SQLite's [sqlite-vec](https://github.com/asg017/sqlite-vec)
or PostgreSQL's [pg-vector](https://github.com/pgvector/pgvector).

mruby-llm also includes support for OpenAI's vector store API. It
provides a vector database as a HTTP service but we won't cover
that here.

```ruby
llm  = LLM.openai(key: ENV["KEY"])
body = "mruby-llm is mruby's capable AI runtime."
embedding = llm.embed([body]).embeddings.first

# Document is your own model with a vector column
# (e.g. sqlite-vec or pgvector)
Document.create!(
  title: "mruby-llm",
  body:,
  embedding:,
)
```

### MCP

The Model Context Protocol (MCP) has first-class support
in mruby-llm. The stdio and http transports work out of the
box. MCP tools are translated into subclasses of
[`LLM::Tool`](https://r.uby.dev/api-docs/llm.rb/LLM/Tool.html) that can be
used with
[`LLM::Context`](https://r.uby.dev/api-docs/llm.rb/LLM/Context.html) or
[`LLM::Agent`](https://r.uby.dev/api-docs/llm.rb/LLM/Agent.html).

```ruby
llm = LLM.deepseek(key: ENV["KEY"])
mcp = LLM::MCP.stdio(argv: ["ruby", "server.rb"])

mcp.run do
  agent = LLM::Agent.new(llm, stream: $stdout, tools: mcp.tools)
  agent.talk "Use the available tools to inspect the environment."
end
```

##### Persistent connections

Set `persistent: true` on the HTTP client to reuse
connections across requests. This uses the persistent
curl transport under the hood and avoids opening a new
TCP connection for every request:

```ruby
mcp = LLM::MCP.http(
  url: "https://api.githubcopilot.com/mcp/",
  headers: {"Authorization" => "Bearer #{ENV['GITHUB_PAT']}"},
  persistent: true
)
```

### A2A

The Agent 2 Agent (A2A) protocol has first-class support
in mruby-llm. The http and jsonrpc transports work out of the
box. A2A skills are translated into subclasses of
[`LLM::Tool`](https://r.uby.dev/api-docs/llm.rb/LLM/Tool.html) that can be
used with
[`LLM::Context`](https://r.uby.dev/api-docs/llm.rb/LLM/Context.html) or
[`LLM::Agent`](https://r.uby.dev/api-docs/llm.rb/LLM/Agent.html).

```ruby
llm   = LLM.deepseek(key: ENV["KEY"])
a2a   = LLM::A2A.rest(url: "https://remote-agent.example.com")
agent = LLM::Agent.new(llm, stream: $stdout, tools: a2a.skills)
agent.talk "Run the skill"
```

##### Persistent connections

The A2A HTTP transport is curl-based by default, so connections are
reused across requests without extra configuration. Pass a concrete
`LLM::Transport` class or instance through `transport:` to override it:

```ruby
a2a = LLM::A2A.rest(url: "https://agent.example.com")
a2a = LLM::A2A.jsonrpc(url: "https://agent.example.com")
```

### Images

A handful of providers can generate images from a text prompt.
OpenAI, Google, xAI, and DeepInfra all support it. The API is
the same across providers:

```ruby
llm = LLM.openai(key: ENV["KEY"])
res = llm.images.create(prompt: "a dog on a rocket to the moon")
File.binwrite "rocket.png", res.images[0].string
```

##### DeepSeek

DeepSeek does not have a dedicated image model, but the runtime
generates SVG vector graphics through its text model. Each
generation produces a valid SVG document that can be converted
to PNG with tools like `rsvg-convert`. Pass an existing agent
to maintain a session across generations:

```ruby
llm = LLM.deepseek(key: ENV["KEY"])

##
# First generation
res = llm.images.create(prompt: "a rocket on the moon")
File.binwrite "rocket.svg", res.images[0].string

##
# Refine with follow-up prompts (shares context)
res = llm.images.create(prompt: "add a dog next to the rocket",
                        agent: res.agent)
File.binwrite "rocket-with-dog.svg", res.images[0].string
```

## FAQ

<details>
<summary>What providers does mruby-llm support?</summary>
<br>
<p>

**Cloud**

The following cloud-based providers are available to choose from. <br>
In no particular order:

🇺🇸 OpenAI <br>
🇺🇸 DeepInfra <br>
🇺🇸 xAI <br>
🇺🇸 Google (Gemini) <br>
🇺🇸 Anthropic <br>
🇨🇳 DeepSeek <br>
🇨🇳 zAI <br>
🇨🇳 Moonshot AI (Kimi) <br>
🇨🇳 Alibaba (Qwen3) <br>
🇪🇺 Mistral <br>

**Weights**

The following providers provide access to open-weight models. <br>
In no particular order:

🇺🇸 DeepInfra <br>
🇨🇳 DeepSeek <br>
🇨🇳 zAI <br>
🇨🇳 Moonshot AI (Kimi) <br>
🇨🇳 Alibaba (Qwen3) <br>
🇪🇺 Mistral <br>

**Local**

The following providers can be run locally on your own hardware. <br>
In no particular order:

* Ollama
* Llamacpp
</p>
</details>

<details>
<summary>I have a limited budget. What should I do?</summary>
<br>
<p>
There are a few options. The first option is to host
your own model, and use the ollama or llamacpp
providers. This can be difficult though because
a capable model requires hardware that can
match it. If you have the ability to self-host,
this would be my first option.
</p>
<p>
The second option is DeepSeek. <br>
The deepseek-v4-flash model costs pennies to use. <br>
And mruby-llm has been optimized for deepseek. For example,
DeepSeek does not have image generation capabilities
but on the mruby-llm runtime it does (vector graphics only,
though).
</p>
<p>
The same is true for structured outputs. DeepSeek does
not support structured outputs in the same way as OpenAI or
Google, but the mruby-llm runtime makes it appear as
though it does, through the `json_object` response
type.
</p>
If you're on a budget, DeepSeek is hard to beat.
</details>

## Applications

mruby-llm is used to build small terminal applications that are
available to the general public over SSH.

| Application | Try it | Runtime |
| --- | --- | --- |
| [matz](https://r.uby.dev/matz/) | `ssh matz@r.uby.dev` | [mruby-llm](https://r.uby.dev/mruby-llm/) |
| [robert](https://4.4bsd.dev/robert) | `ssh robert@4.4bsd.dev` | [mruby-llm](https://r.uby.dev/mruby-llm/) |

## Resources

The [r.uby.dev](https://r.uby.dev) homepage also includes more learning material
and resources.

- [r.uby.dev/mruby-llm](https://r.uby.dev/mruby-llm/)
- [llm.rb](https://r.uby.dev/llm/)

## License

This software is released under the terms of the MIT license. <br>
See [LICENSE](./LICENSE) for details.
