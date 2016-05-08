require 'rubytree'
require_relative 'formula'

class Tableau
  class SignedFormula
    attr_accessor :expanded, :formula, :sign

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

    def initialize(formula, index=1)
      @current_index = index
      @entries = [SignedFormula.new(formula, false, @current_index)]
      super("#{index}: #{formula}")
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
        else
          raise "Don't know how to expand #{expansion_type}"
        end
      end
    end

    def next_entry_to_expand
      @entries.find(&:should_expand?)
    end
  end
end
