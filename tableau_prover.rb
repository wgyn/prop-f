require 'rubytree'
require_relative 'formula'

class Tableau
  class SignedFormula
    attr_accessor :expanded
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
      # TODO: Incrementing of indices should be handled by Tableau
      @index = index
      @expanded = false
    end

    def should_expand?
      !@formula.atomic? && !@expanded
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
      "#{@index}: #{@sign ? 'T' : 'F'}" \
        "(#{@formula.to_s})#{@expanded ? ' EXPANDED' : ''}"
    end
  end

  # A Node represents a collection of SignedFormulas. When expanding a
  # Node, not all the entries will get expanded at once.
  class Node < Tree::TreeNode
    attr_reader :entries

    def initialize(signed_formula)
      @entries = [signed_formula]
      super("#{signed_formula.index}: #{signed_formula.formula}")
    end

    # Disjunctive rules cause the node to split, while non-disjunctive
    # rules simply add to the entries of the current node.
    def expand!
      while entry = (next_entry_to_expand)
        expansion_type, expanded_formulas = entry.expansion
        entry.expanded = true

        case expansion_type
        when :unary, :conjunctive
          @entries += expanded_formulas
        when :disjunctive
          expanded_formulas.each do |signed_formula|
            self << Node.new(signed_formula)
            # This is a recursive call!
            self.children.each {|node| node.expand!}
          end
        end
      end
    end

    def next_entry_to_expand
      @entries.find(&:should_expand?)
    end
  end

  # Create a fully expanded Tableau proof from a formula
  def self.generate(formula)
    signed_formula = SignedFormula.new(formula, false, 1)
    tableau = Node.new(signed_formula)
    tableau.expand!
    tableau
  end

  def self.is_valid?(formula)
    tableau = self.generate(formula)
    raise NotImplementedError
    # TODO: A tableau is valid if every branch is closed. A branch is
    #       closed if it contains contradictory atomic entries i.e. F(p)
    #       and T(p) for some proposition p.
  end
end
