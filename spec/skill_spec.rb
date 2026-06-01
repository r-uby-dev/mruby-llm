# frozen_string_literal: true

describe "LLM::Skill" do
  let(:root) { File.join(File.dirname(__FILE__), "fixtures") }
  let(:skill_dir) { File.join(root, "skills", "frontmatter-skill") }
  let(:skill) { LLM::Skill.load(skill_dir) }

  before do
    Class.new(LLM::Tool) do
      name "frontmatter-read-file"
    end
  end

  describe ".load" do
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
  end
end

Minitest.run(ARGV) || exit(1)
