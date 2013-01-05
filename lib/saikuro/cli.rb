module Saikuro

  require 'saikuro/filter'
  require 'saikuro/formatters'

  # Really ugly command line runner stuff here for now

  class CLI
    require 'stringio'
    require 'optparse'
    require 'fileutils'
    require 'find'

    def self.get_ruby_files(path)
      files = Array.new
      Find.find(path) do |f|
        if !FileTest.directory?(f)
    if f =~ /rb$/
      files<< f
    end
        end
      end
      files
    end

    def self.run( args )
      files = Array.new
      output_dir = "./"
      formater = "html"
      state_filter = Filter.new(5)
      token_filter = Filter.new(10, 25, 50)
      comp_state = comp_token = false

      opts = OptionParser.new do |opts|

        opts.banner = %{saikuro [ -h ] [-o output_directory] [-f type] [ -c, -t ] } +
                      %{[ -C, -w, -e, -T, -W, -E - number ] ( -i file | -D directory ) }

        opts.on( %{-o}, %{--output_directory [DIRECTORY]}, String,
                 %{A directory to output the results in.  },
                 %{The current directory is used if this option is not passed} ) do |dirname|
          output_dir = dirname
        end

        opts.on( %{-f}, %{--formatter ( html | text )}, [:html, :text],
                 %{The format to output the results in - defaults to HTML.} ) do |format|
          formatter = format
        end

        opts.on( %{-c}, %{--cyclo}, %{Compute the cyclomatic complexity of the input.} ) do
          comp_state = true
        end

        opts.on( %{-t}, %{--tokens}, %{Count the number of tokens per line of the input.} ) do
          comp_token = true
        end

        opts.on( %{-C}, %{--filter-cyclo [NUMBER]},
                 [ 1 ... 1000 ],
                 %{Filter the output to only include methods whose complexity is greater } +
                 %{than the passed number.} ) do |cyclo_threshold|
          state_filter.limit = cyclo_threshold
        end

        opts.on( %{-w}, %{--warn-cyclo [NUMBER]},
                 [ 1 ... 1000 ],
                 %{Highlight with a warning methods whose cyclomatic complexity is greater } +
                 %{than or equal to the passed number.} ) do |cyclo_warn|
          state_filter.warn = cyclo_warn.to_i
        end

        opts.on( %{-e}, %{--error-cyclo [NUMBER]},
                 [ 1 ... 1000 ],
                 %{Highlight with an error methods whose cyclomatic complexity is greater } +
                 %{than or equal to the passed number.} ) do |cyclo_error|
          token_filter.error = cyclo_error.to_i
        end

        opts.on( %{-T}, %{--filter-token [NUMBER]},
                 [ 1 ... 1000 ],
                 %{Filter the output to only include methods whose token count is greater } +
                 %{than the passed number.} ) do |token_threshold|
          token_threshold.limit = token_threshold
        end

        opts.on( %{-W}, %{--warn-token [NUMBER]},
                 [ 1 ... 1000 ],
                 %{Highlight with a warning methods whose token count is greater } +
                 %{than or equal to the passed number.} ) do |token_warn|
          token_threshold.warn = token_warn.to_i
        end

        opts.on( %{-E}, %{--error-token [NUMBER]},
                 [ 1 ... 1000 ],
                 %{Highlight with an error methods whose token count is greater } +
                 %{than or equal to the passed number.} ) do |token_error|
          token_threshold.error = token_error.to_i
        end

        opts.on( %{-i}, %{--input-file [path/to/file]}, String,
                 %{Read input from file (may specify multiple times} ) do |file_name|
          files << file_name
        end

        opts.on( %{-D}, %{--input-directory [path/to/directory]}, String,
                 %{Read all ruby files found under directory} ) do |file_name|
          files.concat(get_ruby_files(file_name))
        end

        opts.on( %{-v}, %{--verbose}, %{Increase verboseness of output} ) do
          $VERBOSE = true
        end

      end

      opts.parse( args )

      if formater =~ /html/i
        state_formater = Formatter::StateHTMLComplexity.new(STDOUT,state_filter)
        token_count_formater = Formatter::HTMLTokenCounter.new(STDOUT,token_filter)
      else
        state_formater = Formatter::ParseState.new(STDOUT,state_filter)
        token_count_formater = Formatter::TokenCounter.new(STDOUT,token_filter)
      end

      state_formater = nil if !comp_state
      token_count_formater = nil if !comp_token

      idx_states, idx_tokens = Saikuro.analyze(files,
                                               state_formater,
                                               token_count_formater,
                                               output_dir)

      Formatter.write_cyclo_index(idx_states, output_dir)
      Formatter.write_token_index(idx_tokens, output_dir)
    end

  end

end
