require 'spec_helper'

describe Policial::AccusationPolicy do
  describe '#allowed_for?' do
    context 'when line with violation has not been previously commented on' do
      it 'returns true' do
        pull_request = stub_pull_request
        commenting_policy = described_class.new(pull_request)

        expect(commenting_policy).to be_allowed_for(stub_violation)
      end
    end

    context 'when line with violation has been previously commented on' do
      context 'when comment includes violation message' do
        it 'returns false' do
          violation = stub_violation(
            filename: 'foo.rb',
            messages: ['Trailing whitespace detected']
          )
          comment = stub_comment(
            body: 'Trailing whitespace detected<br>Extra newline',
            original_position: violation.patch_position,
            path: violation.filename
          )
          pull_request = stub_pull_request(comments: [comment])
          commenting_policy = described_class.new(pull_request)

          expect(commenting_policy).not_to be_allowed_for(violation)
        end
      end

      context 'when comment exists for the same line but different files' do
        it 'returns true' do
          violation = stub_violation(
            filename: 'foo.rb',
            messages: ['Trailing whitespace detected']
          )
          comment = stub_comment(
            body: 'Trailing whitespace detected',
            original_position: violation.patch_position,
            path: 'bar.rb'
          )
          pull_request = stub_pull_request(comments: [comment])
          commenting_policy = described_class.new(pull_request)

          expect(commenting_policy).to be_allowed_for(violation)
        end
      end

      context 'when comment does not include violation message' do
        it 'returns true' do
          violation = stub_violation(
            filename: 'foo.rb',
            messages: ['Trailing whitespace detected']
          )
          comment = stub_comment(
            body: 'Extra newline',
            original_position: violation.patch_position,
            path: violation.filename
          )
          pull_request = stub_pull_request(comments: [comment])
          commenting_policy = described_class.new(pull_request)

          expect(commenting_policy).to be_allowed_for(violation)
        end
      end
    end
  end

  def stub_comment(options = {})
    double(:comment, options)
  end

  def stub_violation(options = {})
    defaults = {
      filename: 'foo.rb',
      messages: ['Extra newline'],
      patch_position: 1
    }
    double(:violation, defaults.merge(options))
  end

  def stub_pull_request(options = {})
    defaults = { opened?: true, comments: [] }
    double(:pull_request, defaults.merge(options))
  end
end
