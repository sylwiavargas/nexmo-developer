class SnippetVariablesFilter < Banzai::Filter
  def call(input)
    input.gsub(/```snippet_variables(.+?)```/m) do |_s|
      config = YAML.safe_load($1)

      raise 'No variables provided' unless config
      raise 'Must provide a list' unless config.is_a?(Array)

      output = <<~HEREDOC
        Key | Description
        -- | --
      HEREDOC
      config.each do |key|
        details = variables[key]
        output += <<~HEREDOC
          `#{key}` | #{details['description']}
        HEREDOC
      end

      output
    end
  end

  def variables
    @variables ||= YAML.safe_load(File.read("#{Rails.configuration.docs_base_path}/config/code_snippet_variables.yml"))
  end
end
