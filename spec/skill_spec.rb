# frozen_string_literal: true

describe "LLM::Skill" do
  let(:root) { File.join(File.dirname(__FILE__), "fixtures") }

  before do
    Class.new(LLM::Tool) do
      name "frontmatter-read-file"
    end
  end

  describe ".load" do
    describe "with a tool list" do
      let(:skill_dir) { File.join(root, "skills", "frontmatter-skill") }
      let(:skill) { LLM::Skill.load(skill_dir) }

      it "parses indented frontmatter names" do
        expect(skill.name).must_equal "frontmatter-skill"
      end

      it "parses indented frontmatter descriptions" do
        expect(skill.description).must_equal "Frontmatter skill"
      end

      it "parses indented frontmatter tools" do
        expect(skill.tools.first.name).must_equal "frontmatter-read-file"
      end

      it "keeps the body as instructions" do
        expect(skill.instructions).must_equal "Use frontmatter.\n"
      end

      it "does not inherit tools" do
        expect(skill.inherit_tools?).must_equal false
      end
    end

    describe "with tools: inherit" do
      let(:skill_dir) { File.join(root, "skills", "inherit-skill") }
      let(:skill) { LLM::Skill.load(skill_dir) }

      it "parses indented frontmatter names" do
        expect(skill.name).must_equal "inherit-skill"
      end

      it "parses indented frontmatter descriptions" do
        expect(skill.description).must_equal "Inherit skill"
      end

      it "returns an empty tool list" do
        expect(skill.tools).must_be_empty
      end

      it "inherits tools from parent" do
        expect(skill.inherit_tools?).must_equal true
      end
    end
  end
end

Minitest.run(ARGV) || exit(1)
