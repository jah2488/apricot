require 'apricot/ast'

module Apricot
  class Parser
    class ParseError < StandardError; end

    IDENTIFIER = /[A-Za-z0-9`~!@#\$%^&*_=+<.>\/?:'\\|-]/

    # @param [String] source a source program
    def initialize(source)
      @source = source
      @location = 0
      @line = 1
    end

    # @return [Array] a list of the forms in the program
    def parse
      program = []
      next_char

      skip_whitespace
      while @char
        program << parse_form
        skip_whitespace
      end

      program
    end

    private
    # Parse Lisp forms until the given character is encountered
    # @param [String] terminator the character to stop parsing at
    # @return [Array] a list of the Lisp forms parsed
    def parse_forms_until(terminator)
      skip_whitespace
      forms = []

      while @char
        if @char == terminator
          next_char # consume the terminator
          return forms
        end

        forms << parse_form
        skip_whitespace
      end

      # Can only reach here if we run out of chars without getting a terminator
      raise ParseError, "Unexpected end of program, expected #{terminator}"
    end

    # Parse a single Lisp form
    # @return the code representation of the form
    def parse_form
      case @char
      when '(' then parse_list
      when '[' then parse_array
      when '{' then parse_hash
      when '"' then parse_string
      when ':' then parse_symbol
      when /\d/ then parse_number
      when IDENTIFIER
        if @char =~ /[+-]/ && peek_char =~ /\d/
          parse_number
        else
          parse_identifier
        end
      else raise ParseError, "Unexpected character: #{@char}"
      end
    end

    # Skips whitespace, commas, and comments
    def skip_whitespace
      while @char =~ /[\s,;]/
        # Comments begin with a semicolon and extend to the end of the line
        if @char == ';'
          while @char && @char != "\n"
            next_char
          end
        else
          next_char
        end
      end
    end

    def parse_list
      next_char # skip the (
      AST::List.new(@line, parse_forms_until(')'))
    end

    def parse_array
      next_char # skip the [
      AST::Array.new(@line, parse_forms_until(']'))
    end

    def parse_hash
      next_char # skip the {
      forms = parse_forms_until('}')
      raise ParseError, "Odd number of forms in key-value hash" if forms.count.odd?

      hash = {}
      forms.each_slice(2) {|key, value| hash[key] = value }
      AST::Hash.new(@line, hash)
    end

    def parse_string
      # TODO
    end

    def parse_symbol
      next_char # skip the :
      symbol = ""

      while @char =~ IDENTIFIER
        symbol << @char
        next_char
      end

      raise ParseError, "Empty symbol name" if symbol.empty?

      AST::Symbol.new(@line, symbol)
    end

    def parse_number
      number = ""

      while @char =~ IDENTIFIER
        number << @char
        next_char
      end

      case number
      when /^[+-]?\d+$/ then AST::Integer.new(@line, number.to_i)
      when /^([+-]?)(\d+)r(\d+)$/ then AST::Integer.new(@line, ($1 + $3).to_i($2.to_i))
      when /^[+-]?\d+\.?\d*(?:e[+-]?\d+)?$/ then AST::Float.new(@line, number.to_f)
      when /^([+-]?\d+)\/(\d+)$/ then AST::Rational.new(@line, $1.to_i, $2.to_i)
      else raise ParseError, "Invalid number: #{number}"
      end
    end

    def parse_identifier
      identifier = ""

      while @char =~ IDENTIFIER
        identifier << @char
        next_char
      end

      AST::Identifier.new(@line, identifier)
    end

    def next_char
      @line += 1 if @char == "\n"
      @char = @source[@location,1]
      @char = nil if @char.empty?
      @location += 1 if @char
      @char
    end

    def peek_char
      char = @source[@location,1]
      char = nil if char.empty?
      char
    end
  end
end