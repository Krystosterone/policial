require 'spec_helper'

describe Policial::StyleGuides::CoffeeScript do
  subject do
    described_class.new(
      Policial::RepoConfig.new(
        Policial::Commit.new('volmer/cerberus', 'commitsha')
      )
    )
  end

  describe '.config_file' do
    it 'defaults to .coffeescript.yml' do
      expect(described_class.config_file).to eq('.coffeescript.yml')
    end

    it 'can be overwritten' do
      old_value = described_class.config_file

      described_class.config_file = '.coffeescript.yml'
      expect(described_class.config_file).to eq('.coffeescript.yml')

      described_class.config_file = old_value
    end
  end

  describe '#enabled?' do
    it 'is true' do
      expect(subject.enabled?).to be(true)
    end
  end

  describe '#violations_in_file' do
    before do
      stub_contents_request_with_content(
        'volmer/cerberus',
        sha: 'commitsha',
        file: '.coffeescript.yml',
        content: custom_config.to_yaml
      )
    end
    let(:custom_config) { nil }

    context 'with no violations' do
      it 'does not detect violations' do
        file = build_file('test.coffee', '')
        violations = subject.violations_in_file(file)

        expect(violations.count).to eq(0)
      end
    end

    context 'with some violations' do
      it 'detects violations that do not follow idiomatic CoffeeScript' do
        file = build_file('test.coffee', 'class naughtyBoy')
        violations = subject.violations_in_file(file)

        expect(violations.count).to eq(1)
        expect(violations.first.filename).to eq('test.coffee')
        expect(violations.first.line_number).to eq(1)
        expect(violations.first.messages).to eq(['Class names should be camel cased'])
      end

      it 'returns only one violation containing all offenses per line' do
        file_content = ['throw "error"', ' class naughtyBoy', 'hello?']
        file = build_file('test.rb', file_content)

        violations = subject.violations_in_file(file)

        expect(violations.count).to eq(2)

        expect(violations.first.filename).to eq('test.rb')
        expect(violations.first.line_number).to eq(1)
        expect(violations.first.messages).to eq(['Throwing strings is forbidden'])

        expect(violations.last.filename).to eq('test.rb')
        expect(violations.last.line_number).to eq(2)
        expect(violations.last.messages).to eq([
          "[stdin]:2:1: error: unexpected indentation\n class naughtyBoy\n^",
          'Line contains inconsistent indentation',
          'Class names should be camel cased'
        ])
      end
    end

    context 'with a custom configuration' do
      let(:custom_config) do
        {
          'arrow_spacing' => {
            'level' => 'error'
          }
        }
      end

      it 'detects offenses to the custom style guide' do
        file = build_file('test.rb', 'x((a,b)-> 3)')
        violations = subject.violations_in_file(file)

        expect(violations.count).to eq(1)
        expect(violations.first.filename).to eq('test.rb')
        expect(violations.first.line_number).to eq(1)
        expect(violations.first.messages).to eq(['Function arrow (->) must be spaced properly'])
      end
    end

    context 'with excluded files' do
      let(:custom_config) do
        {
          'AllCops' => {
            'Exclude' => ['lib/test.rb']
          }
        }
      end

      it 'has no violations' do
        file = build_file('lib/test.rb', 4, '"Awful code"')
        violations = subject.violations_in_file(file)

        expect(violations).to be_empty
      end
    end
  end

  def build_file(name, *lines)
    file = double('CommitFile', filename: name, content: lines.join("\n"))
    allow(file).to receive(:line_at) { |n| lines[n]  }
    file
  end
end
