class SmartlingPreprocessorPipeline < Banzai::Pipeline
  def initialize(_options = {})
    super(
      I18n::FrontmatterFilter,
      I18n::TableNormalizerFilter
    )
  end
end
