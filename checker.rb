module Formulas
  class AbstractFormula
    def self.symbol
      raise NotImplementedError
    end
  end

  class BinaryInfixFormula < AbstractFormula
    def initialize(arg1, arg2); @arg1, @arg2 = [arg1, arg2]; end
    def to_s; "#{@arg1} #{symbol} #{@arg2}"; end
    def self.parse(string)
      arg1, arg2 = string.gsub(/\s+/, '').split(symbol)
      self.new(arg1, arg2)
    end
  end

  class Conjunction < BinaryInfixFormula
    def self.symbol; '&&'; end
  end

  class Disjunction < BinaryInfixFormula
    def self.symbol; '||'; end
  end

  class Implication < BinaryInfixFormula
    def self.symbol; '->'; end
  end

  class Negation < AbstractFormula
    def initialize(arg); @arg = arg; end
    def to_s; "#{symbol}#{arg}"; end
    def self.symbol; '!'; end
    def self.parse(string)
      arg = string.match(/^#{symbol}([a-z]+)/)[1]
      self.new(arg)
    end
  end
end

class Prover
  def initialize
    puts 'Hello, world!'
  end

  def test_validity(formula)
    true
  end
end
