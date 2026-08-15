# frozen_string_literal: true

##
# The {LLM::Cost LLM::Cost} class represents an approximate
# cost breakdown for a provider request. It stores input,
# output, input audio, output audio, input image, cache read, cache write,
# and reasoning costs separately and can return the total.
class LLM::Cost
  ##
  # Build a cost breakdown from token usage and model pricing.
  # @param [LLM::Context] ctx
  #  Context used to resolve provider, model, and token usage
  # @return [LLM::Cost]
  def self.from(ctx)
    pricing = LLM.registry_for(ctx.llm).cost(model: ctx.model)
    usage = ctx.usage
    output = usage.output_tokens - usage.reasoning_tokens
    input = usage.input_tokens - usage.cache_read_tokens
    new(
      input_costs: price(pricing.input, input),
      output_costs: price(pricing.output, output),
      input_audio_costs: price(pricing.input_audio, usage.input_audio_tokens),
      output_audio_costs: price(pricing.output_audio, usage.output_audio_tokens),
      input_image_costs: price(pricing.input, usage.input_image_tokens),
      cache_read_costs: price(pricing.cache_read, usage.cache_read_tokens),
      cache_write_costs: price(pricing.cache_write, usage.cache_write_tokens),
      reasoning_costs: price(pricing.reasoning || pricing.output, usage.reasoning_tokens)
    )
  rescue LLM::NoSuchModelError, LLM::NoSuchRegistryError
    new
  end

  ##
  # @api private
  def self.price(rate, tokens)
    return if tokens.nil? || tokens.to_i.zero?
    return if rate.nil? || rate.to_f.zero?
    ((rate.to_f / 1_000_000.0) * tokens.to_i).round(12)
  end

  ##
  # @param [Float, nil] input_costs
  # @param [Float, nil] output_costs
  # @param [Float, nil] input_audio_costs
  # @param [Float, nil] output_audio_costs
  # @param [Float, nil] input_image_costs
  # @param [Float, nil] cache_read_costs
  # @param [Float, nil] cache_write_costs
  # @param [Float, nil] reasoning_costs
  # @return [LLM::Cost]
  def initialize(input_costs: nil, output_costs: nil, input_audio_costs: nil,
                 output_audio_costs: nil, input_image_costs: nil,
                 cache_read_costs: nil, cache_write_costs: nil,
                 reasoning_costs: nil)
    @input_costs = input_costs
    @output_costs = output_costs
    @input_audio_costs = input_audio_costs
    @output_audio_costs = output_audio_costs
    @input_image_costs = input_image_costs
    @cache_read_costs = cache_read_costs
    @cache_write_costs = cache_write_costs
    @reasoning_costs = reasoning_costs
  end

  ##
  # @return [Boolean]
  #  Returns true when two costs hold the same breakdown
  def ==(other)
    other.is_a?(LLM::Cost) and other.to_h == to_h
  end
  alias_method :eql?, :==

  ##
  # @return [Float]
  #  Returns the input cost
  def input
    @input_costs || 0.to_f
  end
  alias_method :input_costs, :input

  ##
  # @return [Float]
  #  Returns the output cost
  def output
    @output_costs || 0.to_f
  end
  alias_method :output_costs, :output

  ##
  # @return [Float]
  #  Returns the input audio cost
  def input_audio
    @input_audio_costs || 0.to_f
  end
  alias_method :input_audio_costs, :input_audio

  ##
  # @return [Float]
  #  Returns the output audio cost
  def output_audio
    @output_audio_costs || 0.to_f
  end
  alias_method :output_audio_costs, :output_audio

  ##
  # @return [Float]
  #  Returns the input image cost
  def input_image
    @input_image_costs || 0.to_f
  end
  alias_method :input_image_costs, :input_image

  ##
  # @return [Float]
  #  Returns the cache read cost
  def cache_read
    @cache_read_costs || 0.to_f
  end
  alias_method :cache_read_costs, :cache_read

  ##
  # @return [Float]
  #  Returns the cache write cost
  def cache_write
    @cache_write_costs || 0.to_f
  end
  alias_method :cache_write_costs, :cache_write

  ##
  # @return [Float]
  #  Returns the reasoning cost
  def reasoning
    @reasoning_costs || 0.to_f
  end
  alias_method :reasoning_costs, :reasoning

  ##
  # @return [Float]
  #  Returns the total cost
  def total
    [
      input_costs, output_costs,
      input_audio_costs, output_audio_costs,
      cache_read_costs, cache_write_costs,
      input_image_costs, reasoning_costs
    ].compact.sum.round(12)
  end

  ##
  # @return [Hash]
  #  Returns a hash with the non-nil cost components and the total
  def to_h
    {
      input:, output:,
      cache_read:, cache_write:,
      input_audio:, output_audio:, input_image:,
      reasoning:, total:
    }.compact
  end

  ##
  # @return [String]
  #  Returns the total cost in a human friendly format
  def to_s
    format("%.2f", total)
  end
end
