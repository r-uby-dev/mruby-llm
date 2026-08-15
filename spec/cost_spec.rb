# frozen_string_literal: true

describe "LLM::Cost" do
  let(:root) { File.join(File.dirname(__FILE__), "fixtures") }
  let(:transport) { LLM::Test::Transport.new(root:) }
  let(:llm) { LLM.openai(key: "test-key", transport:) }

  describe "short aliases" do
    let(:cost) do
      LLM::Cost.new(
        input_costs: 0.0015,
        output_costs: 0.012,
        input_audio_costs: 0.0009,
        output_audio_costs: 0.0048,
        input_image_costs: 0.00075,
        cache_read_costs: 0.0015,
        cache_write_costs: 0.000625,
        reasoning_costs: 0.024
      )
    end

    it "creates aliases" do
      expect(cost.input).must_equal cost.input_costs
      expect(cost.output).must_equal cost.output_costs
      expect(cost.input_audio).must_equal cost.input_audio_costs
      expect(cost.output_audio).must_equal cost.output_audio_costs
      expect(cost.input_image).must_equal cost.input_image_costs
      expect(cost.cache_read).must_equal cost.cache_read_costs
      expect(cost.cache_write).must_equal cost.cache_write_costs
      expect(cost.reasoning).must_equal cost.reasoning_costs
    end

    it "computes the total" do
      expect(cost.total).must_equal 0.046075
    end

    it "zero-fills missing cost components with Float accessors" do
      empty = LLM::Cost.new
      expect(empty.input).must_equal 0.0
      expect(empty.output).must_equal 0.0
      expect(empty.input_audio).must_equal 0.0
      expect(empty.output_audio).must_equal 0.0
      expect(empty.input_image).must_equal 0.0
      expect(empty.cache_read).must_equal 0.0
      expect(empty.cache_write).must_equal 0.0
      expect(empty.reasoning).must_equal 0.0
      expect(empty.total).must_equal 0.0
    end

    it "zero-fills cost components in to_h" do
      cost = LLM::Cost.new(input_costs: 0.0015, output_costs: 0.012)
      expect(cost.to_h).must_equal(
        input: 0.0015,
        output: 0.012,
        input_audio: 0,
        output_audio: 0,
        input_image: 0,
        cache_read: 0,
        cache_write: 0,
        reasoning: 0,
        total: 0.0135
      )
    end

    it "formats the total with two decimals" do
      expect(LLM::Cost.new.to_s).must_equal "0.00"
      expect(cost.to_s).must_equal "0.05"
    end

    it "compares costs by breakdown" do
      other = LLM::Cost.new(
        input_costs: 0.0015,
        output_costs: 0.012,
        input_audio_costs: 0.0009,
        output_audio_costs: 0.0048,
        input_image_costs: 0.00075,
        cache_read_costs: 0.0015,
        cache_write_costs: 0.000625,
        reasoning_costs: 0.024
      )
      expect(cost == other).must_equal true
      expect(cost.eql?(other)).must_equal true
      expect(cost == LLM::Cost.new).must_equal false
    end
  end

  describe ".from" do
    let(:ctx) { LLM::Context.new(llm, model: "gpt-4.1") }

    before do
      transport.stub("POST", "/v1/chat/completions", fixture: "openai/chat_completions_cost.json")
      ctx.talk("hello")
    end

    it "builds a cost breakdown from usage and pricing" do
      cost = ctx.cost
      expect(cost).must_be_instance_of LLM::Cost
      expect(cost.input).must_equal 0.001
      expect(cost.output).must_equal 0.0128
      expect(cost.cache_read).must_equal 0.00025
      expect(cost.reasoning).must_equal 0.0032
      expect(cost.input_audio).must_equal 0
      expect(cost.total).must_equal 0.01725
    end

    it "returns an empty cost for unknown models" do
      other = LLM::Context.new(llm, model: "no-such-model")
      cost = other.cost
      expect(cost).must_be_instance_of LLM::Cost
      expect(cost.total).must_equal 0
    end
  end
end

Minitest.run(ARGV) || exit(1)
