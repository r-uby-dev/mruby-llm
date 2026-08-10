# frozen_string_literal: true

##
# The {LLM::Cost LLM::Cost} class represents an approximate
# cost breakdown for a provider request. It stores input,
# output, input audio, output audio, input image, cache read, cache write,
# and reasoning costs separately and can return the total.
#
# @attr [Float] input_costs
#   Returns the input cost, aliased as `input`
# @attr [Float] output_costs
#   Returns the output cost, aliased as `output`
# @attr [Float, nil] input_audio_costs
#   Returns the input audio cost, or nil when no input audio tokens
#   were used, aliased as `input_audio`
# @attr [Float, nil] output_audio_costs
#   Returns the output audio cost, or nil when no output audio tokens
#   were used, aliased as `output_audio`
# @attr [Float, nil] input_image_costs
#   Returns the input image cost, or nil when no input image tokens
#   were used, aliased as `input_image`
# @attr [Float, nil] cache_read_costs
#   Returns the cache read cost, or nil when no cache tokens
#   were used, aliased as `cache_read`
# @attr [Float, nil] cache_write_costs
#   Returns the cache write cost, or nil when no cache creation
#   tokens were used, aliased as `cache_write`
# @attr [Float, nil] reasoning_costs
#   Returns the reasoning cost, or nil when no reasoning tokens
#   were used, aliased as `reasoning`
class LLM::Cost < Struct.new(
  :input_costs, :output_costs,
  :input_audio_costs, :output_audio_costs,
  :cache_read_costs, :cache_write_costs,
  :input_image_costs, :reasoning_costs,
  keyword_init: true
)
  ##
  # Build a cost breakdown from token usage and model pricing.
  # @param [LLM::Context] ctx
  #  Context used to resolve provider, model, and token usage
  # @return [LLM::Cost]
  def self.from(ctx)
    pricing = LLM.registry_for(ctx.llm).cost(model: ctx.model)
    new(
      input_costs: price(pricing.input, ctx.usage.input_tokens),
      output_costs: price(pricing.output, ctx.usage.output_tokens),
      input_audio_costs: price(pricing.input_audio, ctx.usage.input_audio_tokens),
      output_audio_costs: price(pricing.output_audio, ctx.usage.output_audio_tokens),
      input_image_costs: price(pricing.input, ctx.usage.input_image_tokens),
      cache_read_costs: price(pricing.cache_read, ctx.usage.cache_read_tokens),
      cache_write_costs: price(pricing.cache_write, ctx.usage.cache_write_tokens),
      reasoning_costs: price(pricing.output, ctx.usage.reasoning_tokens)
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
    format("%.12f", total).sub(/\.?0+$/, "")
  end

  ##
  # Aliases
  alias_method :input, :input_costs
  alias_method :output, :output_costs
  alias_method :input_audio, :input_audio_costs
  alias_method :output_audio, :output_audio_costs
  alias_method :cache_read, :cache_read_costs
  alias_method :cache_write, :cache_write_costs
  alias_method :input_image, :input_image_costs
  alias_method :reasoning, :reasoning_costs
end
