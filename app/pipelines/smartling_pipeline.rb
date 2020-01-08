class SmartlingPipeline < Banzai::Pipeline
  def initialize(_options = {})
    super(
      I18n::Smartling::FrontmatterFilter,
      I18n::Smartling::EscapeFilter,
      I18n::Smartling::CodeBlockFilter
    )
  end
end
