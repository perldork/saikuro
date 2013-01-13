module Saikuro

  require 'stringio'
  require 'optparse'
  require 'fileutils'
  require 'find'
  require 'pathname'

  require 'saikuro/filter'
  require 'saikuro/formatters'

  # Command-line interface
  # * Parse command-line options
  # * Run token / cyclomatic complexity tests
  # * Output results

  POSITIVE_INTEGERS = /^(?:[1-9][0-9]*)$/

  class CLI

    def self.get_ruby_files( path )
      files = []
      Find.find(path) do |f|
        files << f if f.end_with?( %{.rb} ) and FileTest.file?(f)
      end
      files
    end

    def self.parse_cli_options( args )

      options = {
        files:              Array.new,
        output_directory:   %{./},
        formatter:          :html,
        complexity_filter:  Filter.new( 5 ),
        token_filter:       Filter.new( 10, 25, 50 ),
        compute_complexity: false,
        compute_tokens:     false
      }

      opts = OptionParser.new do |opts|

        opts.banner = %{saikuro [ -h ] [-o output_directory] [-f type] [ -c, -t ] } +
                      %{[ -C, -w, -e, -T, -W, -E - number ] ( -i file | -D directory ) }

        opts.on(
          %{-o}, %{--output_directory DIRECTORY}, String,
          %{A directory to output the results in.},
          %{The current directory is used if this},
          %{option is not present} 
        ) do |directory_name|
          options[ :output_directory ] = directory_name
        end

        opts.on( %{-f}, %{--formatter FORMAT}, [ :html ],
                 %{The format to output the results in - HTML currently only } +
                 %{supported format.} ) do |format|
          options[ :formatter ] = format
        end

        opts.on( %{-c}, %{--cyclo}, %{Compute the cyclomatic complexity of the input.} ) do
          options[ :compute_complexity ] = true
        end

        opts.on( %{-t}, %{--tokens}, %{Count the number of tokens per line of the input.} ) do
          options[ :compute_tokens ] = true
        end


        opts.on( %{-C}, %{--filter-cyclo NUMBER},
                 POSITIVE_INTEGERS,
                 %{Filter the output to only include methods whose complexity is greater } +
                 %{than the passed number.} ) do |cyclomatic_threshold|
          options[ :complexity_filter ].limit = cyclomatic_threshold.to_i
        end

        opts.on( %{-w}, %{--warn-cyclo NUMBER},
                 POSITIVE_INTEGERS,
                 %{Highlight with a warning methods whose cyclomatic complexity is greater } +
                 %{than or equal to the passed number.} ) do |cyclomatic_warning_threshold|
          options[ :complexity_filter ].warn = cyclomatic_warning_threshold.to_i
        end

        opts.on( %{-e}, %{--error-cyclo NUMBER},
                 POSITIVE_INTEGERS,
                 %{Highlight with an error methods whose cyclomatic complexity is greater } +
                 %{than or equal to the passed number.} ) do |cyclomatic_error_threshold|
          options[ :complexity_filter ].error = cyclomatic_error_threshold.to_i
        end

        opts.on( %{-T}, %{--filter-token NUMBER},
                 POSITIVE_INTEGERS,
                 %{Filter the output to only include methods whose token count is greater } +
                 %{than the passed number.} ) do |token_count_threshold|
          options[ :token_filter ].limit = token_count_threshold.to_i
        end

        opts.on( %{-W}, %{--warn-token NUMBER},
                 POSITIVE_INTEGERS,
                 %{Highlight with a warning methods whose token count is greater },
                 %{than or equal to the passed number.} ) do |token_warning_threshold|
          options[ :token_filter ].warn = token_warning_threshold.to_i
        end

        opts.on( %{-E}, %{--error-token NUMBER},
                 POSITIVE_INTEGERS,
                 %{Highlight with an error methods whose token count is greater } +
                 %{than or equal to the passed number.} ) do |token_error_threshold|
          options[ :token_filter ].error = token_error_threshold.to_i
        end

        opts.on( %{-i}, %{--input-file path/to/file}, String,
                 %{Read input from file (may specify multiple times} ) do |file_name|
          options[ :files ] << file_name
        end

        opts.on( %{-D}, %{--input-directory path/to/directory}, String,
                 %{Read all ruby files found under directory} ) do |file_name|
          options[ :files ].concat get_ruby_files( file_name )
        end

        opts.on( %{-v}, %{--verbose}, %{Increase verboseness of output} ) do
          $VERBOSE = true
        end


      end

      opts.parse( args )

      if options[ :files ].empty?
        opts.abort( %{Must specify either an input file or input directory with files to parse!} )
      end

      options

    end

    def self.choose_formatters( options )

      complexity_formatter = nil
      token_count_formatter = nil

      if options[ :compute_complexity ]
        complexity_formatter = case options[ :formatter ]
          when :html
            Formatter::StateHTMLComplexity.new( STDOUT, options[ :complexity_filter ] )
          else
            Formatter::ParseState.new( STDOUT, options[ :complexity_filter ] )
          end
      end

      if options[ :compute_tokens ]
        token_count_formatter = case options[ :formatter ]
          when :html
              Formatter::HTMLTokenCounter.new( STDOUT, options[ :token_filter ] )
          else
              Formatter::TokenCounter.new( STDOUT, options[ :token_filter ] )
          end
      end

      return complexity_formatter, token_count_formatter

    end

    def self.run( args )

      options = parse_cli_options( args )

      FileUtils.makedirs( options[ :output_directory ] ) \
        unless Dir.exists? options[ :output_directory ]

      if options[ :formatter ] == :html
        real_path = Pathname.new( options[ :output_directory ] ).realpath
        Formatter::HTMLStyleSheet.file_name = \
          %{#{ real_path }/#{ Formatter::HTMLStyleSheet.css_name }}
      end

      complexity_formatter, token_count_formatter = choose_formatters( options )

      idx_cyclo, idx_tokens = Saikuro.analyze( options[ :files ],
                                                complexity_formatter,
                                                token_count_formatter,
                                                options[ :output_directory ] )

      Formatter.write_results( options[ :output_directory ], idx_cyclo, idx_tokens )

    end

  end

end
