module Apricot
  module AST
    class Node
      attr_reader :line

      def initialize(line)
        @line = line
      end

      def pos(g)
        g.set_line(@line)
      end
    end

    class NodeStub < Node
      attr_reader :value

      def initialize(line, value)
        super(line)
        @value = value
      end
    end

    # TODO: Replace stubs with AST classes in lib/apricot/ast/
    class List < NodeStub
    end

    class Identifier < NodeStub
    end
  end
end

%w{literal array hash root script evalexpression}.map do |r|
  require "apricot/ast/#{r}"
end
