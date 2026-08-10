# frozen_string_literal: true

describe "LLM::Registry" do
  let(:registry) { LLM::Registry.for(provider) }

  context "when given openai" do
    let(:provider) { :openai }

    context "#cost" do
      context "when given the gpt-4.1 model" do
        let(:cost) { registry.cost(model: "gpt-4.1") }
        let(:limit) { registry.limit(model: "gpt-4.1") }

        it "returns the expected values" do
          expect(cost).must_be_instance_of LLM::Object
          expect(cost.input).must_equal 2
          expect(cost.output).must_equal 8
          expect(limit.context).must_equal 1047576
        end
      end

      context "when given the gpt-5.3-codex model" do
        let(:cost) { registry.cost(model: "gpt-5.3-codex") }
        let(:modalities) { registry.modalities(model: "gpt-5.3-codex") }

        it "returns the expected values" do
          expect(cost).must_be_instance_of LLM::Object
          expect(cost.input).must_equal 1.75
          expect(cost.output).must_equal 14
          expect(modalities.input).must_equal ["text", "image", "pdf"]
        end
      end

      context "when given a dated gpt-4.1 model" do
        it "returns the gpt-4.1 cost object" do
          expect(registry.cost(model: "gpt-4.1-2025-01-01")).must_equal(
            registry.cost(model: "gpt-4.1")
          )
        end
      end

      context "when given gpt-4-0613" do
        it "returns the gpt-4 cost object" do
          expect(registry.cost(model: "gpt-4-0613")).must_equal(
            registry.cost(model: "gpt-4")
          )
        end
      end
    end
  end

  context "when given google" do
    let(:provider) { :google }

    context "#cost" do
      it "returns an object for gemini-3.1-pro-preview-customtools" do
        cost = registry.cost(model: "gemini-3.1-pro-preview-customtools")
        expect(cost).must_be_instance_of LLM::Object
        expect(cost.input).must_equal 2
        expect(cost.output).must_equal 12
        expect(cost.context_over_200k.input).must_equal 4
      end

      it "returns an object for gemini-embedding-001" do
        cost = registry.cost(model: "gemini-embedding-001")
        limit = registry.limit(model: "gemini-embedding-001")
        expect(cost).must_be_instance_of LLM::Object
        expect(cost.input).must_equal 0.15
        expect(cost.output).must_equal 0
        expect(limit.context).must_equal 2048
      end
    end
  end

  context "when given anthropic" do
    let(:provider) { :anthropic }

    context "#cost" do
      it "returns an object for claude-opus-5" do
        cost = registry.cost(model: "claude-opus-5")
        expect(cost).must_be_instance_of LLM::Object
        expect(cost.input).must_equal 5
        expect(cost.output).must_equal 25
        expect(cost.cache_write).must_equal 6.25
      end

      it "returns an object for claude-haiku-4-5-20251001" do
        limit = registry.limit(model: "claude-haiku-4-5-20251001")
        modalities = registry.modalities(model: "claude-haiku-4-5-20251001")
        expect(registry.cost(model: "claude-haiku-4-5-20251001").input).must_equal 1
        expect(limit.context).must_equal 200000
        expect(modalities.input).must_equal ["text", "image", "pdf"]
      end
    end
  end

  context "when given deepseek" do
    let(:provider) { :deepseek }

    context "#cost" do
      it "returns an object for deepseek-chat" do
        cost = registry.cost(model: "deepseek-chat")
        expect(cost).must_be_instance_of LLM::Object
        expect(cost.input).must_equal 0.14
        expect(cost.cache_read).must_equal 0.0028
      end

      it "returns an object for deepseek-reasoner" do
        limit = registry.limit(model: "deepseek-reasoner")
        expect(registry.cost(model: "deepseek-reasoner").output).must_equal 0.28
        expect(limit.output).must_equal 384000
      end
    end
  end

  context "when given xai" do
    let(:provider) { :xai }

    context "#cost" do
      it "returns an object for grok-4.3" do
        cost = registry.cost(model: "grok-4.3")
        expect(cost).must_be_instance_of LLM::Object
        expect(cost.input).must_equal 1.25
        expect(cost.output).must_equal 2.5
      end

      it "returns an object for grok-4.20-0309-non-reasoning" do
        cost = registry.cost(model: "grok-4.20-0309-non-reasoning")
        limit = registry.limit(model: "grok-4.20-0309-non-reasoning")
        expect(cost).must_be_instance_of LLM::Object
        expect(cost.context_over_200k.output).must_equal 5
        expect(limit.context).must_equal 1000000
      end
    end
  end

  context "when given zai" do
    let(:provider) { :zai }

    context "#cost" do
      it "returns an object for glm-5" do
        cost = registry.cost(model: "glm-5")
        limit = registry.limit(model: "glm-5")
        expect(cost).must_be_instance_of LLM::Object
        expect(cost.output).must_equal 3.2
        expect(limit.output).must_equal 131072
      end

      it "returns an object for glm-4.5-air" do
        cost = registry.cost(model: "glm-4.5-air")
        expect(cost).must_be_instance_of LLM::Object
        expect(cost.input).must_equal 0.2
        expect(cost.cache_read).must_equal 0.03
      end
    end
  end

  context "when given deepinfra" do
    let(:provider) { :deepinfra }

    context "#cost" do
      it "returns an object for zai-org/GLM-5.2" do
        cost = registry.cost(model: "zai-org/GLM-5.2")
        expect(cost).must_be_instance_of LLM::Object
        expect(cost.input).must_equal 0.75
        expect(cost.output).must_equal 2.4
      end
    end
  end

  context "when given moonshot" do
    let(:provider) { :moonshot }

    context "#cost" do
      it "returns an object for kimi-k3" do
        cost = registry.cost(model: "kimi-k3")
        expect(cost).must_be_instance_of LLM::Object
        expect(cost.input).must_equal 3
        expect(cost.output).must_equal 15
      end
    end
  end
end

Minitest.run(ARGV) || exit(1)
