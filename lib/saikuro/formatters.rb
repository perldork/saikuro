module Saikuro
  module Formatter

    class Base
      attr_accessor :warnings, :errors, :current

      def initialize(out, filter = nil)
        @out = out
        @filter = filter
        reset_data
      end

      def warn_error?(num, marker)
        klass = ""

        if @filter.error?(num)
          klass = ' class="error"'
          @errors<< [@current, marker, num]
        elsif @filter.warn?(num)
          klass = ' class="warning"'
          @warnings<< [@current, marker, num]
        end

        klass
      end

      def reset_data
        @warnings = Array.new
        @errors = Array.new
        @current = ""
      end

    end

    class TokenCounter < Base

      def start(new_out=nil)
        reset_data
        @out = new_out if new_out
        @out.puts "Token Count"
      end

      def start_count(number_of_files)
        @out.puts "Counting tokens for #{number_of_files} files."
      end

      def start_file(file_name)
        @current = file_name
        @out.puts "File:#{file_name}"
      end

      def line_token_count(line_number,number_of_tokens)
        return if @filter.ignore?(number_of_tokens)
        warn_error?(number_of_tokens, line_number)
        @out.puts "Line:#{line_number} ; Tokens : #{number_of_tokens}"
      end

      def end_file
        @out.puts ""
      end

      def end_count
      end

      def end
      end

    end

    module HTMLStyleSheet
      def HTMLStyleSheet.style_sheet
        out = StringIO.new

        out.puts "<style>"
        out.puts 'body {'
        out.puts '	margin: 20px;'
        out.puts '	padding: 0;'
        out.puts '	font-size: 12px;'
        out.puts '	font-family: bitstream vera sans, verdana, arial, sans serif;'
        out.puts '	background-color: #efefef;'
        out.puts '}'
        out.puts ''
        out.puts 'table {	'
        out.puts '	border-collapse: collapse;'
        out.puts '	/*border-spacing: 0;*/'
        out.puts '	border: 1px solid #666;'
        out.puts '	background-color: #fff;'
        out.puts '	margin-bottom: 20px;'
        out.puts '}'
        out.puts ''
        out.puts 'table, th, th+th, td, td+td  {'
        out.puts '	border: 1px solid #ccc;'
        out.puts '}'
        out.puts ''
        out.puts 'table th {'
        out.puts '	font-size: 12px;'
        out.puts '	color: #fc0;'
        out.puts '	padding: 4px 0;'
        out.puts '	background-color: #336;'
        out.puts '}'
        out.puts ''
        out.puts 'th, td {'
        out.puts '	padding: 4px 10px;'
        out.puts '}'
        out.puts ''
        out.puts 'td {	'
        out.puts '	font-size: 13px;'
        out.puts '}'
        out.puts ''
        out.puts '.class_name {'
        out.puts '	font-size: 17px;'
        out.puts '	margin: 20px 0 0;'
        out.puts '}'
        out.puts ''
        out.puts '.class_complexity {'
        out.puts 'margin: 0 auto;'
        out.puts '}'
        out.puts ''
        out.puts '.class_complexity>.class_complexity {'
        out.puts '	margin: 0;'
        out.puts '}'
        out.puts ''
        out.puts '.class_total_complexity, .class_total_lines, .start_token_count, .file_count {'
        out.puts '	font-size: 13px;'
        out.puts '	font-weight: bold;'
        out.puts '}'
        out.puts ''
        out.puts '.class_total_complexity, .class_total_lines {'
        out.puts '	color: #c00;'
        out.puts '}'
        out.puts ''
        out.puts '.start_token_count, .file_count {'
        out.puts '	color: #333;'
        out.puts '}'
        out.puts ''
        out.puts '.warning {'
        out.puts '	background-color: yellow;'
        out.puts '}'
        out.puts ''
        out.puts '.error {'
        out.puts '	background-color: #f00;'
        out.puts '}'
        out.puts "</style>"

        out.string
      end

      def style_sheet
        HTMLStyleSheet.style_sheet
      end
    end


    class HTMLTokenCounter < TokenCounter
      include HTMLStyleSheet

      def start(new_out=nil)
        reset_data
        @out = new_out if new_out
        @out.puts "<html>"
        @out.puts style_sheet
        @out.puts "<body>"
      end

      def start_count(number_of_files)
        @out.puts "<div class=\"start_token_count\">"
        @out.puts "Number of files: #{number_of_files}"
        @out.puts "</div>"
      end

      def start_file(file_name)
        @current = file_name
        @out.puts "<div class=\"file_count\">"
        @out.puts "<p class=\"file_name\">"
        @out.puts "File: #{file_name}"
        @out.puts "</p>"
        @out.puts "<table width=\"100%\" border=\"1\">"
        @out.puts "<tr><th>Line</th><th>Tokens</th></tr>"
      end

      def line_token_count(line_number,number_of_tokens)
        return if @filter.ignore?(number_of_tokens)
        klass = warn_error?(number_of_tokens, line_number)
        @out.puts "<tr><td>#{line_number}</td><td#{klass}>#{number_of_tokens}</td></tr>"
      end

      def end_file
        @out.puts "</table>"
      end

      def end_count
      end

      def end
        @out.puts "</body>"
        @out.puts "</html>"
      end
    end

    class ParseState < Base

      def start(new_out=nil)
        reset_data
        @out = new_out if new_out
      end

      def end
      end

      def start_class_compute_state(type_name,name,complexity,lines)
        @current = name
        @out.puts "-- START #{name} --"
        @out.puts "Type:#{type_name} Name:#{name} Complexity:#{complexity} Lines:#{lines}"
      end

      def end_class_compute_state(name)
        @out.puts "-- END #{name} --"
      end

      def def_compute_state(name,complexity,lines)
        return if @filter.ignore?(complexity)
        warn_error?(complexity, name)
        @out.puts "Type:Def Name:#{name} Complexity:#{complexity} Lines:#{lines}"
      end

    end

    class StateHTMLComplexity < ParseState
      include HTMLStyleSheet

      def start(new_out=nil)
        reset_data
        @out = new_out if new_out
        @out.puts "<html><head><title>Cyclometric Complexity</title></head>"
        @out.puts style_sheet
        @out.puts "<body>"
      end

      def end
        @out.puts "</body>"
        @out.puts "</html>"
      end

      def start_class_compute_state(type_name,name,complexity,lines)
        @current = name
        @out.puts "<div class=\"class_complexity\">"
        @out.puts "<h2 class=\"class_name\">#{type_name} : #{name}</h2>"
        @out.puts "<div class=\"class_total_complexity\">Total Complexity: #{complexity}</div>"
        @out.puts "<div class=\"class_total_lines\">Total Lines: #{lines}</div>"
        @out.puts "<table width=\"100%\" border=\"1\">"
        @out.puts "<tr><th>Method</th><th>Complexity</th><th># Lines</th></tr>"
      end

      def end_class_compute_state(name)
        @out.puts "</table>"
        @out.puts "</div>"
      end

      def def_compute_state(name, complexity, lines)
        return if @filter.ignore?(complexity)
        klass = warn_error?(complexity, name)
        @out.puts "<tr><td>#{name}</td><td#{klass}>#{complexity}</td><td>#{lines}</td></tr>"
      end

    end

    def self.summarize_errors_and_warnings(enw, header)
      return "" if enw.empty?
      f = StringIO.new
      erval = Hash.new { |h,k| h[k] = Array.new }
      wval = Hash.new { |h,k| h[k] = Array.new }

      enw.each do |fname, warnings, errors|
        errors.each do |c,m,v|
          erval[v] << [fname, c, m]
        end
        warnings.each do |c,m,v|
          wval[v] << [fname, c, m]
        end
      end

      f.puts "<h2 class=\"class_name\">Errors and Warnings</h2>"
      f.puts "<table width=\"100%\" border=\"1\">"
      f.puts header

      f.puts self.print_summary_table_rows(erval, "error")
      f.puts self.print_summary_table_rows(wval, "warning")
      f.puts "</table>"

      f.string
    end

    def self.print_summary_table_rows(ewvals, klass_type)
      f = StringIO.new
      ewvals.sort { |a,b| b <=> a}.each do |v, vals|
        vals.sort.each do |fname, c, m|
          f.puts "<tr><td><a href=\"./#{fname}\">#{c}</a></td><td>#{m}</td>"
          f.puts "<td class=\"#{klass_type}\">#{v}</td></tr>"
        end
      end
      f.string
    end

    def self.list_analyzed_files(files)
      f = StringIO.new
      f.puts "<h2 class=\"class_name\">Analyzed Files</h2>"
      f.puts "<ul>"
      files.each do |fname, warnings, errors|
        readname = fname.split("_")[0...-1].join("_")
        f.puts "<li>"
        f.puts "<p class=\"file_name\"><a href=\"./#{fname}\">#{readname}</a>"
        f.puts "</li>"
      end
      f.puts "</ul>"
      f.string
    end

    def self.write_index(files, filename, title, header)
      return if files.empty?

      File.open(filename,"w") do |f|
        f.puts "<html><head><title>#{title}</title></head>"
        f.puts "#{HTMLStyleSheet.style_sheet}\n<body>"
        f.puts "<h1>#{title}</h1>"

        enw = files.find_all { |fn,w,e| (!w.empty? || !e.empty?) }

        f.puts self.summarize_errors_and_warnings(enw, header)

        f.puts "<hr/>"
        f.puts self.list_analyzed_files(files)
        f.puts "</body></html>"
      end
    end

    def self.write_cyclo_index(files, output_dir)
      header = "<tr><th>Class</th><th>Method</th><th>Complexity</th></tr>"
      self.write_index(files,
                  "#{output_dir}/index_cyclo.html",
                  "Index for cyclomatic complexity",
                  header)
    end

    def self.write_token_index(files, output_dir)
      header = "<tr><th>File</th><th>Line #</th><th>Tokens</th></tr>"
      self.write_index(files,
                  "#{output_dir}/index_token.html",
                  "Index for tokens per line",
                  header)
    end

  end
end
