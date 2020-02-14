require 'rails_helper'

RSpec.describe I18n::TableNormalizerFilter do
  let(:full_table) do
    <<~TABLE
      | Action | Description | Synchronous |
      | -- | -- | -- |
      |[record](#record) | All or part of a Call | No|
      |[conversation](#conversation) | Create or join an existing [Conversation](/conversation/concepts/conversation) | Yes|


      > **Note**: [Connect an inbound call](/voice/voice-api/code-snippets/connect-an-inbound-call) provides an example of how to serve your NCCOs to Nexmo after a Call or Conference is initiated
    TABLE
  end

  context 'with a complete table' do
    it 'does not alter the table' do
      expect(described_class.call(full_table)).to eq(full_table)
    end
  end

  context 'without a complete table' do
    let(:table) do
      <<~TABLE
        | Action | Description | Synchronous |
        -- | -- | --
        [record](#record) | All or part of a Call | No
        [conversation](#conversation) | Create or join an existing [Conversation](/conversation/concepts/conversation) | Yes


        > **Note**: [Connect an inbound call](/voice/voice-api/code-snippets/connect-an-inbound-call) provides an example of how to serve your NCCOs to Nexmo after a Call or Conference is initiated
      TABLE
    end

    it 'adds the missing delimiters' do
      expect(described_class.call(table)).to eq(full_table)
    end
  end
end
