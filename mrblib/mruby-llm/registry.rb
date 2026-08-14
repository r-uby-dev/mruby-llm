# frozen_string_literal: true

##
# The {LLM::Registry LLM::Registry} class provides a small API over
# provider model data. It exposes model metadata such as pricing,
# capabilities, modalities, and limits from the registry files
# stored under `data/`. The data is provided by https://models.dev
# and shipped with llm.rb.
class LLM::Registry
  @root = File.expand_path("../..", File.dirname(__FILE__))

  ##
  # @raise [LLM::Error]
  #  Might raise an error
  # @param [Symbol]
  #  A provider name
  # @return [LLM::Registry]
  def self.for(name)
    path = File.join @root, "data", "#{name}.json"
    if File.file?(path)
      new LLM.json.load(File.read(path))
    else
      raise LLM::NoSuchRegistryError, "no registry found for #{name}"
    end
  end

  ##
  # @param [Hash] blob
  #  A model registry
  # @return [LLM::Registry]
  def initialize(blob)
    @registry = LLM::Object.from(blob)
    @models = @registry.models
  end

  ##
  # Returns the model keys (names) in the registry.
  # @return [Array<String>]
  def keys
    @models.keys
  end

  ##
  # Returns all models as {LLM::Registry::Model} objects.
  # @return [Array<LLM::Registry::Model>]
  def models
    @models.map { |id, data| Model.new(data.merge(id:)) }
  end

  ##
  # @return [Array<String>]
  def env
    @registry.env
  end

  ##
  # @return [LLM::Object]
  #  Returns model costs
  def cost(model:)
    find(model:).cost
  end

  ##
  # @return [LLM::Object]
  #  Returns model modalities
  def modalities(model:)
    find(model:).modalities
  end

  ##
  # @return [LLM::Object]
  #  Returns model limits such as the context window size
  def limit(model:)
    find(model:).limit
  end

  private

  ##
  # Find a model, or raise an error
  # @param [String] model
  #  Model ID
  # @return [LLM::Registry::Model]
  def find(model:)
    if @models.key?(model)
      Model.new(@models[model])
    else
      fallback = fallback_model(model) || "none"
      if @models.key?(fallback)
        Model.new(@models[fallback])
      else
        raise LLM::NoSuchModelError, "no such model: #{model} (fallback: #{fallback})"
      end
    end
  end

  ##
  # @api private
  def fallback_model(model)
    return model[0...-11] if model =~ /-\d{4}-\d{2}-\d{2}$/
    return model[0...-5] if model =~ /\Agpt-.*-\d{4}$/
    nil
  end
end
