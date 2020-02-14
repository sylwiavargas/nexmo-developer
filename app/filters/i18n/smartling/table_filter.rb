module I18n
  module Smartling
    class TableFilter < Banzai::Filter
      def call(input)
        input.gsub(/((\|\s)?(--\s(\|\s)?)+--(\s\|)?\n)(\|\s?.*?\|\s[\p{Han}a-zA-Z0-9]+\s?\|)\n\n/m) do |_table|
          body = $6
          header = $1.chomp("\n")
          columns = header.scan('--').size

          rows = body
                 .gsub("\n*", '</br>')
                 .gsub("\n</br>", '</br>')
                 .gsub("\n\n", '</br>')
                 .split('|')
                 .flat_map { |s| s.split(/\n/) }
                 .in_groups_of(columns)

          <<~TABLE
            #{header}
            #{rows.map { |row| row.join('|').yield_self { |s| "|#{s}|" } }.join("\n")}

          TABLE
        end
      end
    end
  end
end
