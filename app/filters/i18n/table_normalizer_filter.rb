module I18n
  class TableNormalizerFilter < Banzai::Filter
    def call(input)
      input.gsub(/^(\|?\s?(--\s?(\|\s)?)+--\s?\|?)\n((\s?.*?\|\s.*?\s?))\n\n/m) do |_table|
        body = $4
        header = $1.chomp("\n")
        header = header.yield_self { |s| "| #{s} |" } unless header.starts_with?('|')
        columns = header.scan('--').size

        rows = body.split('|').flat_map { |s| s.split("\n") }.in_groups_of(columns)

        <<~TABLE
          #{header}
          #{rows.map { |row| row.join('|').yield_self { |s| "|#{s}|" } }.join("\n")}


        TABLE
      end
    end
  end
end
