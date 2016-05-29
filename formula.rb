module Formula
  class AbstractFormula
    def self.symbol
      raise NotImplementedError
    end

    def atomic?; false; end
  end

  class BinaryInfixFormula < AbstractFormula
    attr_accessor :arg1, :arg2
    def initialize(arg1, arg2); @arg1, @arg2 = [arg1, arg2]; end
    def to_s; "#{@arg1} #{symbol} #{@arg2}"; end
    def self.parse(string)
      arg1, arg2 = string.gsub(/\s+/, '').split(symbol)
      self.new(arg1, arg2)
    end
  end

  class And < BinaryInfixFormula
    def symbol; '&&'; end
  end

  class Or < BinaryInfixFormula
    def symbol; '||'; end
  end

  class Implies < BinaryInfixFormula
    def symbol; '->'; end
  end

  class Not < AbstractFormula
    attr_accessor :arg
    def initialize(arg); @arg = arg; end
    def to_s; "#{symbol}(#{arg})"; end
    def symbol; '!'; end
    def self.parse(string)
      arg = string.match(/^#{symbol}([a-z]+)/)[1]
      self.new(arg)
    end
  end

  class Atom < AbstractFormula
    attr_accessor :arg
    def initialize(arg); @arg = arg; end
    def atomic?; true; end
    def to_s; @arg; end
  end

  def self.and(p, q); And.new(p, q); end
  def self.or(p, q); Or.new(p, q); end
  def self.implies(p, q); Implies.new(p, q); end
  def self.not(p); Not.new(p); end
  def self.atom(p); Atom.new(p); end
end
