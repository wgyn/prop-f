require 'rubytree'
require 'set'
require_relative 'formula'

class Tableau
  class SignedFormula
    attr_reader :formula, :index, :sign

    EXPANSION_TYPES = {
      [Formula::Not, true] => :unary,
      [Formula::Not, false] => :unary,
      [Formula::And, true] => :conjunctive,
      [Formula::Or, false] => :conjunctive,
      [Formula::Implies, false] => :conjunctive,
      [Formula::And, false] => :disjunctive,
      [Formula::Or, true] => :disjunctive,
      [Formula::Implies, true] => :disjunctive,
    }

    def initialize(formula, sign, index)
      @formula = formula
      @sign = sign
      @index = index
    end

    # Returns a tuple, where first element is the expansion type and second
    # element is an array of expanded SignedFormulas.
    def expansion
      expanded_formulas = \
        case @formula
        when Formula::Not
          [
            SignedFormula.new(@formula.arg, !@sign, @index + 1),
          ]
        when Formula::And
          [
            SignedFormula.new(@formula.arg1, @sign, @index + 1),
            SignedFormula.new(@formula.arg2, @sign, @index + 2),
          ]
        when Formula::Or
          [
            SignedFormula.new(@formula.arg1, @sign, @index + 1),
            SignedFormula.new(@formula.arg2, @sign, @index + 2),
          ]
        when Formula::Implies
          [
            SignedFormula.new(@formula.arg1, !@sign, @index + 1),
            SignedFormula.new(@formula.arg2, @sign, @index + 2),
          ]
        end
      expansion_type = EXPANSION_TYPES[[@formula.class, @sign]]

      return nil unless expanded_formulas && expansion_type

      [expansion_type, expanded_formulas]
    end

    def to_s
      "#{@index}: #{@sign ? 'T' : 'F'}(#{@formula.to_s})"
    end
  end

  # A Node represents a collection of SignedFormulas. When expanding a
  # Node, not all the entries will get expanded at once.
  class Node < Tree::TreeNode
    attr_reader :atomic_expansions, :expanded, :unexpanded

    BOOLEAN_VALUES = Set.new([true, false])

    def initialize(signed_formula, atomic_expansions=Hash.new(Set.new))
      @atomic_expansions = atomic_expansions
      @expanded = []
      @unexpanded = [signed_formula]
      super(signed_formula.to_s)
    end

    # Disjunctive rules cause the node to split, while non-disjunctive
    # rules simply add to the entries of the current node.
    def expand_once!
      while to_expand = @unexpanded.pop
        expansion_type, expanded_formulas = to_expand.expansion

        if to_expand.formula.atomic?
          # TODO: Don't use += here...
          @atomic_expansions[to_expand.formula.arg] += [to_expand.sign]
        end
        @expanded << to_expand

        case expansion_type
        when :unary, :conjunctive
          @unexpanded += expanded_formulas.reverse
        when :disjunctive
          expanded_formulas.each do |signed_formula|
            self << Node.new(signed_formula, @atomic_expansions.clone)
          end
        end
      end
    end

    def expand_fully!
      expand_once!
      self.children.each {|node| node.expand_fully!}
    end

    # A tableau is valid if every branch is closed.
    def is_valid?
      leaf_nodes = self.each_leaf
      leaf_nodes.map(&:is_closed?).reduce(&:&)
    end

    # A branch is closed if it contains contradictory atomic formulas
    # i.e. F(p) and T(p) for some formula p
    def is_closed?
      @atomic_expansions.values.include?(BOOLEAN_VALUES)
    end

    private
    def track_atomic_entries!
      atomic_entries = (@expanded + @unexpanded).select {|sf| sf.formula.atomic?}
      atomic_expansions = Hash[
        atomic_entries.map {|sf| [sf.formula.arg, sf.sign]}
      ]
      @atomic_expansions = @atomic_expansions.merge(atomic_expansions)
    end
  end

  # Create a fully expanded Tableau proof from a formula
  def self.generate(formula)
    signed_formula = SignedFormula.new(formula, false, 1)
    tableau = Node.new(signed_formula)
    tableau.expand_fully!
    tableau
  end

  def self.is_valid?(formula)
    tableau = self.generate(formula)
    tableau.is_valid?
  end
end
