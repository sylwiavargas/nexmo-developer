require 'rails_helper'

RSpec.describe SnippetVariablesFilter do
  it 'returns whitespace with whitespace input' do
    input = ' '

    expected_output = ' '

    expect(described_class.call(input)).to eql(expected_output)
  end

  it 'returns unaltered non-matching input' do
    input = 'some text'

    expected_output = 'some text'

    expect(described_class.call(input)).to eql(expected_output)
  end

  it 'outputs multiple lines' do
    input = <<~HEREDOC
      ```snippet_variables
      - NEXMO_API_KEY
      - TO_NUMBER
      ```
    HEREDOC

    expected_output = <<~HEREDOC
      Key | Description
      -- | --
      `NEXMO_API_KEY` | You can find this in your account overview
      `TO_NUMBER` | The number you are sending the SMS to in E.164 format. For example `447700900000`.

    HEREDOC

    expect(described_class.call(input)).to eq(expected_output)
  end

  it 'throws with an empty list' do
    input = <<~HEREDOC
      ```snippet_variables
      ```
    HEREDOC

    expect do
      described_class.new.call(input)
    end.to raise_error('No variables provided')
  end

  it 'throws with the wrong data type' do
    input = <<~HEREDOC
      ```snippet_variables
      Not a list
      ```
    HEREDOC

    expect do
      described_class.new.call(input)
    end.to raise_error('Must provide a list')
  end
end
