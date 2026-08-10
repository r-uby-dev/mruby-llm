# frozen_string_literal: true

describe "LLM::Function concurrency" do
  let(:tool_class) do
    Class.new(LLM::Tool) do
      name "echo"
      parameter :value, String, "The value"
      required %i[value]

      def call(value:)
        {value: value}
      end
    end
  end

  let(:function) do
    tool_class.new.function.tap do |fn|
      fn.id = "call_1"
      fn.arguments = {"value" => "hello"}
    end
  end

  let(:slow_function) do
    Class.new(LLM::Tool) do
      name "slow"
      def call
        sleep 1
        {value: "done"}
      end
    end.new.function.tap do |fn|
      fn.id = "call_slow"
      fn.arguments = {}
    end
  end

  let(:big_function) do
    Class.new(LLM::Tool) do
      name "big"
      def call
        # Larger than the default pipe buffer (~64 KiB on Linux) so a
        # non-blocking fork write would raise Chan::WaitWritable.
        {value: "x" * (256 * 1024)}
      end
    end.new.function.tap do |fn|
      fn.id = "call_big"
      fn.arguments = {}
    end
  end

  let(:functions) do
    [
      function,
      function.dup.tap { |fn| fn.id = "call_2" }
    ].extend(LLM::Function::Array)
  end

  describe "Function#task" do
    it "returns a Sequential::Task for :sequential" do
      task = function.task(:sequential)
      expect(task).must_be_instance_of LLM::Function::Sequential::Task
      expect(task.wait).must_be_instance_of LLM::Function::Return
    end

    it "returns a Task::Task for :task" do
      task = function.task(:task)
      expect(task).must_be_instance_of LLM::Function::Task::Task
      expect(task.wait.value).must_equal({value: "hello"})
    end

    it "returns a Fork::Task for :fork" do
      task = function.task(:fork)
      expect(task).must_be_instance_of LLM::Function::Fork::Task
      expect(task.wait.value).must_equal({value: "hello"})
    end

    it "waits twice on the same :task and returns the same result" do
      task = function.task(:task)
      first = task.wait
      second = task.wait
      expect(second).must_be_same_as first
      expect(second.value).must_equal({value: "hello"})
    end

    it "returns large payloads through :fork without dropping them" do
      result = big_function.task(:fork).wait
      expect(result.value[:value].bytesize).must_equal 256 * 1024
    end

    it "raises for an unknown strategy" do
      expect(proc { function.task(:thread) }).must_raise ArgumentError
    end
  end

  describe "task contract" do
    [:sequential, :task, :fork].each do |strategy|
      describe "with :#{strategy}" do
        it "exposes value as an alias of wait" do
          expected = function.task(strategy).value.to_h
          result = function.task(strategy).wait.to_h
          expect(result).must_equal expected
        end

        it "reports group_class" do
          task = function.task(strategy)
          expect(task.group_class).must_be_instance_of Class
        end

        it "exposes the wrapped function" do
          expect(function.task(strategy).function).must_equal function
        end
      end
    end
  end

  describe "Array#task / Array#wait" do
    [:sequential, :task, :fork].each do |strategy|
      it "waits through :#{strategy} and returns values" do
        returns = functions.wait(strategy)
        expect(returns).must_be_instance_of Array
        expect(returns.size).must_equal 2
        expect(returns.all? { LLM::Function::Return === _1 }).must_equal true
        expect(returns.map(&:value)).must_equal [{value: "hello"}, {value: "hello"}]
      end
    end

    it "returns a group from task" do
      expect(functions.task(:sequential)).must_be_instance_of LLM::Function::Sequential::Group
      expect(functions.task(:task)).must_be_instance_of LLM::Function::Task::Group
      expect(functions.task(:fork)).must_be_instance_of LLM::Function::Fork::Group
    end

    it "waits from the root task without raising join errors" do
      task = function.task(:task)
      expect(task.wait.value).must_equal({value: "hello"})
    end
  end

  describe "Stream::Queue grouping" do
    let(:stream) do
      Class.new(LLM::Stream) do
        attr_reader :events
        def initialize
          @events = []
        end
        def on_tool_return(tool, result)
          @events << [tool.name, result.value]
        end
      end.new
    end

    it "waits queued :task work through group_class" do
      stream.queue << function.task(:task)
      returns = stream.wait
      expect(returns.map(&:value)).must_equal [{value: "hello"}]
      expect(stream.events).must_equal [["echo", {value: "hello"}]]
    end

    it "waits queued :fork work through group_class" do
      stream.queue << function.task(:fork)
      returns = stream.wait
      expect(returns.map(&:value)).must_equal [{value: "hello"}]
      expect(stream.events).must_equal [["echo", {value: "hello"}]]
    end
  end

  describe "interrupt" do
    it "raises LLM::Interrupt from a :task wait after interrupt!" do
      task = slow_function.task(:task).tap(&:spawn)
      task.interrupt!
      expect(proc { task.wait }).must_raise LLM::Interrupt
    end

    it "raises LLM::Interrupt from a :fork wait after interrupt!" do
      task = slow_function.task(:fork).tap(&:spawn)
      task.interrupt!
      expect(proc { task.wait }).must_raise LLM::Interrupt
    end
  end
end

Minitest.run(ARGV) || exit(1)
