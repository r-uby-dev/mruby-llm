<p align="center">
  <a href="https://r.uby.dev/mruby-llm/">
    <img src="rubydev.svg" width="400" height="200" border="0" alt="a r.uby.dev project">
  </a>
</p>

> A [r.uby.dev](https://r.uby.dev) project.

## Welcome

Welcome to the canonical [mruby-llm](https://github.com/r-uby-dev/mruby-llm#readme) repository.

mruby-llm is not a library, framework or toolkit but an advanced
runtime for building highly capable AI applications with mruby.

It is designed for terminal tools, services, small standalone
binaries, and embedded systems. In theory it could run anywhere
mruby runs but in practice it will depend on the device.

Embedded systems are not the only use-case though. mruby is a good
candidate for all kinds of software, and sometimes people think it
is only for embedded devices. That's not the case. It can be used to
build software as or more capable as CRuby can, and on the same
platforms.

## Features

The runtime supports OpenAI, OpenAI-compatible endpoints, Anthropic,
Google Gemini, DeepSeek, xAI, Z.ai, Ollama, and llama.cpp. It has
first-class support for streaming, tool calls, MCP and A2A,
embeddings, vector stores and the RAG pattern.

It supports nearly all the same features as [llm.rb](https://r.uby.dev/llm),
and if you already know llm.rb then you already know mruby-llm:
it is a smaller subset. The type of applications you can build is quite
different though. While CRuby primarily targets the web, mruby allows
you to target a much broader set of platforms, and it also allows you
to distribute your software as a standalone binary.

I think it is accurate to say that mruby-llm is [llm.rb](https://r.uby.dev/llm)
plus the features of the mruby runtime. That's what makes it interesting.
You can do things you wouldn't normally do in CRuby, and that makes it
possible to use the same llm.rb runtime in ways you couldn't before.

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

#### LLM::Agent

The [`LLM::Agent`](https://r.uby.dev/api-docs/llm.rb/LLM/Agent.html)
class is the default high-level interface, and it is recommended for
most use-cases. It manages tool execution automatically, guards against
infinite loops, manages conversation state, and much more.

```ruby
llm = LLM.deepseek(key: ENV["KEY"])
agent = LLM::Agent.new(llm, stream: $stdout)
agent.talk "Hello world"
```

#### LLM::Context

The [`LLM::Context`](https://r.uby.dev/api-docs/llm.rb/LLM/Context.html)
class is at the heart of the runtime and it is what
[`LLM::Agent`](https://r.uby.dev/api-docs/llm.rb/LLM/Agent.html) uses
under the hood. It requires that the tool call loop be managed manually:
sometimes that can be useful, but usually for advanced use-cases.
If you're new to mruby-llm, try
[`LLM::Agent`](https://r.uby.dev/api-docs/llm.rb/LLM/Agent.html) first.

```ruby
llm = LLM.deepseek(key: ENV["KEY"])
ctx = LLM::Context.new(llm, stream: $stdout)
ctx.talk "Hello world"
```

#### LLM::Tool

Subclasses of [`LLM::Tool`](https://r.uby.dev/api-docs/llm.rb/LLM/Tool.html)
are plain Ruby classes with an optional set of typed parameters. The
model can choose to call them on your behalf, and they're one of the
most powerful features for extending the feature set or abilities of a
model.

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
```

#### LLM::Stream

Streams can be simple IO objects or subclasses of
[`LLM::Stream`](https://r.uby.dev/api-docs/llm.rb/LLM/Stream.html)
with structured callbacks for content, reasoning, tool calls, tool
returns, and compaction.

```ruby
class MyStream < LLM::Stream
  def on_content(content)
    print content
  end

  def on_reasoning_content(content)
    warn content
  end
end

llm = LLM.deepseek(key: ENV["KEY"])
agent = LLM::Agent.new(llm, stream: MyStream.new)
agent.talk "Explain Ruby fibers."
```

#### LLM::MCP

The Model Context Protocol (MCP) has first-class support in mruby-llm.
The stdio and http transports work out of the box. MCP tools are
translated into subclasses of
[`LLM::Tool`](https://r.uby.dev/api-docs/llm.rb/LLM/Tool.html) that
can be used with
[`LLM::Context`](https://r.uby.dev/api-docs/llm.rb/LLM/Context.html)
or [`LLM::Agent`](https://r.uby.dev/api-docs/llm.rb/LLM/Agent.html).

```ruby
llm = LLM.deepseek(key: ENV["KEY"])
mcp = LLM::MCP.stdio(argv: ["ruby", "server.rb"])

mcp.run do
  agent = LLM::Agent.new(llm, stream: $stdout, tools: mcp.tools)
  agent.talk "Use the available tools to inspect the environment."
end
```

#### LLM::A2A

The Agent 2 Agent (A2A) protocol has first-class support in mruby-llm.
The rest and jsonrpc transports work out of the box. A2A skills are
translated into subclasses of
[`LLM::Tool`](https://r.uby.dev/api-docs/llm.rb/LLM/Tool.html) that
can be used with
[`LLM::Context`](https://r.uby.dev/api-docs/llm.rb/LLM/Context.html)
or [`LLM::Agent`](https://r.uby.dev/api-docs/llm.rb/LLM/Agent.html).

```ruby
llm = LLM.deepseek(key: ENV["KEY"])
a2a = LLM::A2A.rest(url: "https://remote-agent.example.com")

agent = LLM::Agent.new(llm, stream: $stdout, tools: a2a.skills)
agent.talk "Run the skill"
```

#### RAG

Most providers offer an embedding model that can be used for semantic
search, or similarity search. An embedding model can generate embeddings
that can then be stored in a database that is optimized for storing and
querying vectors, such as SQLite's
[sqlite-vec](https://github.com/asg017/sqlite-vec) or PostgreSQL's
[pg-vector](https://github.com/pgvector/pgvector).

mruby-llm also includes support for OpenAI's vector store API. It
provides a vector database as a HTTP service but we won't cover
that here.

```ruby
llm  = LLM.openai(key: ENV["KEY"])
body = "mruby-llm is mruby's capable AI runtime."
embedding = llm.embed([body]).embeddings.first

Document.create!(
  title: "mruby-llm",
  body:,
  embedding:,
)
```

#### Concurrency

mruby-llm supports multiple tool execution strategies. The choice
between them often depends on the requirements of your application
and the mruby build you ship.

Sequential execution uses `:call`. Lightweight concurrent work can use
`:task`, and process isolation can use `:fork` when the target platform
supports it.

```ruby
llm = LLM.deepseek(key: ENV["KEY"])
tools = [FetchNews, FetchStocks, FetchFeeds]

agent = LLM::Agent.new(llm, tools:, concurrency: :task)
agent.talk "Run the tools concurrently"
```

## Applications

mruby-llm is used to build small terminal applications that are
available to the general public over SSH.

| Application | Try it | Runtime |
| --- | --- | --- |
| [matz](https://r.uby.dev/matz/) | `ssh matz@r.uby.dev` | [mruby-llm](https://r.uby.dev/mruby-llm/) |
| [robert](https://4.4bsd.dev/robert) | `ssh robert@4.4bsd.dev` | [mruby-llm](https://r.uby.dev/mruby-llm/) |

## Resources

- [r.uby.dev/mruby-llm](https://r.uby.dev/mruby-llm/)
- [llm.rb](https://r.uby.dev/llm/)

## License

[BSD Zero Clause](https://choosealicense.com/licenses/0bsd/)
<br>
See [LICENSE](./LICENSE)
