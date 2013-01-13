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
        @out.puts "file_name}"
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

      @@file_name = nil

      def self.file_name=( new_name )
        @@file_name = new_name
      end

      # Return name relative to passed in file if file is passed
      # in to make relative CSS reference paths
      def self.file_name( dest_file = nil )
        return @@file_name if dest_file.nil?
        end_path = Pathname.new( dest_file ).realpath.to_s
        css_path = Pathname.new( @@file_name.match( %r{^.*/} )[ 0 ] ).realpath.to_s
        css_file = @@file_name.match( %r{/([^/]+)$} )[ 1 ]
        end_path.gsub!( css_path,  %{} )
        backpath = %{../} * ( end_path.count( %{/} ) - 1 )
        rel_css_path = backpath + css_file
        if $VERBOSE
          puts %{=========================}
          puts %{CSS PATH:    } + css_path
          puts %{CSS FILE:    } + css_file
          puts %{END PATH:    } + end_path
          puts %{BACK PATH:   } + backpath
          puts %{REL CSS PATH } + rel_css_path
        end
        rel_css_path
      end

      def self.css_name
        %{styles.css}
      end

      def self.style_sheet
        %{
            body {
              margin: 20px;
              padding: 0;
              font-size: 12px;
              font-family: bitstream vera sans, verdana, arial, sans serif;
              background-color: #eee;
            }

            table {	
              border-collapse: collapse;
              /*border-spacing: 0;*/
              width: 80%;
              min-width: 600px;
              align: center;
              border: 1px solid #666;
              background-color: #fff;
              margin-bottom: 20px;
            }

            table, th, th+th, td, td+td  {
              border: 1px solid #ccc;
            }

            table th {
              font-size: 12px;
              color: #333;
              padding: 4px 0;
              background-color: #ccc;
            }

            th, td {
              padding: 4px 10px;
            }

            td {	
              font-size: 13px;
            }

            .class_name {
              font-size: 17px;
              margin: 20px 0 0;
            }

            .class_complexity {
            margin: 0 auto;
            }

            .class_complexity, .class_complexity {
              margin: 0;
            }

            .class_total_complexity, .class_total_lines, .start_token_count, .file_count {
              font-size: 13px;
              font-weight: bold;
            }

            .class_total_complexity, .class_total_lines {
              color: #e00;
            }

            .start_token_count, .file_count {
              color: #333;
            }

            .warning {
              background-color: #FAFCAC;
            }

            .error {
              background-color: #F2C7CC;
            }

        }
      end

    end


    class HTMLTokenCounter < TokenCounter

      include HTMLStyleSheet

      def start(new_out=nil)
        reset_data
        @out = new_out if new_out
        @out.puts %{
          <html>
          <head>
            <link rel="stylesheet" type="text/css" href="#{ HTMLStyleSheet.file_name( @out.path )}"/>
          </head>
          <body>
        }
      end

      def start_count(number_of_files)
        @out.puts %{
          <div class="start_token_count">
          Number of files: #{number_of_files}
          </div>
        }
      end

      def start_file(file_name)
        @current = file_name
        @out.puts %{
          <div class="file_count">
          <p class="file_name">#{file_name}</p>
          <table>
          <tr>
            <th>Line</th><th>Tokens</th>
          </tr>
        }
      end

      def line_token_count(line_number,number_of_tokens)
        return if @filter.ignore?(number_of_tokens)
        klass = warn_error?(number_of_tokens, line_number)
        @out.puts %{
          <tr>
            <td>#{line_number}</td><td#{klass}>#{number_of_tokens}</td>
          </tr>
        }
      end

      def end_file
        @out.puts "</table>"
      end

      def end_count
      end

      def end
        @out.puts %{
          </body>
        </html>
        }
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
        @out.puts %{
         <html>
           <head>
             <title>Cyclometric Complexity</title>
             <link rel="stylesheet" type="text/css" href="#{ HTMLStyleSheet.file_name( @out.path ) }"/>
           </head>
        <body>
        }
      end

      def end
        @out.puts %{
          </body>
        </html>
        }
      end

      def start_class_compute_state(type_name,name,complexity,lines)
        @current = name
        @out.puts %{
          <div class="class_complexity">
          <h2 class="class_name">#{type_name} : #{name}</h2>
          <div class="class_total_complexity">Total Complexity: #{complexity}</div>
          <div class="class_total_lines">Total Lines: #{lines}</div>
          <table>
          <tr>
            <th>Method</th><th>Complexity</th><th># Lines</th>
          </tr>
        }
      end

      def end_class_compute_state(name)
        @out.puts %{
            </table>
          </div>
        }
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

      f.puts %{
        <h2 class="class_name">Errors and Warnings</h2>
        <table>
          #{ header }
          #{ self.print_summary_table_rows(erval, "error")  }
          #{ self.print_summary_table_rows(wval, "warning") }
        </table>
      }
      f.string
    end

    def self.print_summary_table_rows(ewvals, klass_type)
      f = StringIO.new
      ewvals.sort { |a,b| b <=> a}.each do |v, vals|
        vals.sort.each do |fname, c, m|
          f.puts %{
            <tr>
              <td><a href="#{fname.gsub( %r{^/}, %{./} )}">#{c}</a></td>
              <td>#{m}</td>
              <td class="#{klass_type}">#{v}</td>
            </tr>
          }
        end
      end
      f.string
    end

    def self.list_analyzed_files(files)
      f = StringIO.new
      f.puts %{
        <h2 class="class_name">Analyzed Files</h2>
        <ul>
      }
      files.each do |fname, warnings, errors|
        readname = fname.split("_")[0...-1].join("_")
        f.puts %{
            <li>
              <p class="file_name"><a href="./#{fname}">#{readname}</a></p>
            </li>
        }
      end
      f.puts %{
        </ul>
      }
      f.string
    end

    def self.write_stylesheet( file_name )
      File.open( file_name, %{w} ) do|f|
        f.puts HTMLStyleSheet.style_sheet
      end
    end

    def self.write_results( output_dir, cyclo_files, token_files )

      self.write_stylesheet( HTMLStyleSheet.file_name )

      index_file = output_dir + %{/index.html}

      File.open( index_file, %{w} ) do |index|
          cyclo_header = %{<tr><th>Class</th><th>Method</th><th>Complexity</th></tr>}
          token_header = %{<tr><th>File</th><th>Line #</th><th>Tokens</th></tr>}
          index.puts <<-end_of_index
          <html>
            <head>
              <title>Saikuro :: Results</title>
              <link rel="stylesheet" type="text/css" href="#{ HTMLStyleSheet.file_name( index_file ) }" />
            </head>
            <body>
              <h1>Cyclomatic Complexity</h1>
              #{
                enw = cyclo_files.find_all { |fn,w,e| (!w.empty? || !e.empty?) }
                self.summarize_errors_and_warnings(enw, cyclo_header)
              }
              <hr/>
              #{ self.list_analyzed_files(cyclo_files) }
              <h1>Line Complexity - Token Count</h1>
              #{
                enw = token_files.find_all { |fn,w,e| (!w.empty? || !e.empty?) }
                self.summarize_errors_and_warnings(enw, token_header)
              }
              <hr/>
              #{ self.list_analyzed_files(token_files) }
            </body>
          </html>
          end_of_index
      end

    end

  end
end
