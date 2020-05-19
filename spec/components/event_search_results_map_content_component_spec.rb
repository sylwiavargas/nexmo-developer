require "rails_helper"

RSpec.describe EventSearchResultsMapContentComponent, type: :component do
  it "creates an instance of the component class" do
    expect(described_class.new(data: nil)).to be_an_instance_of(EventSearchResultsMapContentComponent)
  end
end
