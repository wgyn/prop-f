require 'rubytree'
require 'set'
require_relative 'formula'

module Tableau
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
      @index = index
      @expanded = false
    end

    # Returns a tuple, where first element is the expansion type and second
    # element is an array of NodeEntries.
    def expansion(index)
      expanded_formulas = \
        case @formula
        when Formula::Not
          [
            SignedFormula.new(@formula.arg, !@sign, index + 1),
          ]
        when Formula::And
          [
            SignedFormula.new(@formula.arg1, @sign, index + 1),
            SignedFormula.new(@formula.arg2, @sign, index + 2),
          ]
        when Formula::Or
          [
            SignedFormula.new(@formula.arg1, @sign, index + 1),
            SignedFormula.new(@formula.arg2, @sign, index + 2),
          ]
        when Formula::Implies
          [
            SignedFormula.new(@formula.arg1, !@sign, index + 1),
            SignedFormula.new(@formula.arg2, @sign, index + 2),
          ]
        end
      expansion_type = EXPANSION_TYPES[[@formula.class, @sign]]

      return nil unless expanded_formulas && expansion_type

      [expansion_type, expanded_formulas]
    end

    def atomic?
      @formula.atomic?
    end

    def to_s
      "#{@index}: #{@sign ? 'T' : 'F'}(#{@formula.to_s}) " \
        "#{@expanded ? 'EXPANDED' : 'UNEXPANDED'}"
    end
  end

  class Node < Tree::TreeNode
    attr_reader :atomic_expansions, :formulas

    BOOLEAN_VALUES = Set.new([true, false])

    def initialize(signed_formula, atomic_expansions=nil)
      @atomic_expansions = atomic_expansions || Hash.new(Set.new)
      @formulas = [signed_formula]
      super(signed_formula.to_s)
    end

    # Disjunctive rules cause the node to split, while non-disjunctive
    # rules simply add to the formulas of the current node.
    def expand_once!
      handle_atomic_formulas!

      idx = @formulas.find_index {|sf| !sf.atomic? && !sf.expanded}
      return unless idx
      to_expand = @formulas[idx]
      expansion_type, new_formulas = to_expand.expansion(root.max_index)

      if is_leaf?
        update_formulas!(expansion_type, new_formulas)
      else
        # Important to materialize the leaves here, otherwise we end up in
        # an infinite recursion when disjunctively expanding the tree
        current_leaves = each_leaf
        current_leaves.each do |node|
          node.update_formulas!(expansion_type, new_formulas)
        end
      end

      to_expand.expanded = true
    end

    def expand_fully!
      while @formulas.find_index {|sf| !sf.expanded}
        expand_once!
      end
      self.children.each {|node| node.expand_fully!}
    end

    # A node fully expanded if it has no unexpanded formulas and is either
    # a) a root node or b) all of its ancestors are fully expanded.
    def fully_expanded?
      @unexpanded.empty? && (
        self.is_root? || parent.fully_expanded?
      )
    end

    # A tableau is valid if every branch is closed.
    def is_valid?
      leaf_nodes = each_leaf
      leaf_nodes.map(&:is_closed?).reduce(&:&)
    end

    # A branch is closed if it contains contradictory atomic formulas
    # i.e. F(p) and T(p) are contained in the branch for some atom p
    def is_closed?
      @atomic_expansions.values.include?(BOOLEAN_VALUES)
    end

    def to_s
      @formulas.map(&:to_s).join("\n")
    end

    def print_tableau
      root.print_tree(
        root.node_depth, nil,
        lambda {|node, prefix| puts "#{prefix} #{node}"},
      )
    end

    protected

    def max_index
      if is_leaf?
        @formulas.map(&:index).max
      else
        leaves = each_leaf
        leaves.map {|n| n.max_index}.max
      end
    end

    def update_formulas!(expansion_type, new_formulas)
      case expansion_type
      when :unary, :conjunctive
        @formulas += new_formulas
      when :disjunctive
        new_formulas.each do |signed_formula|
          self << Node.new(signed_formula, @atomic_expansions.clone)
        end
      end
    end

    private
    def handle_atomic_formulas!
      atomic_formulas = @formulas.select {|sf| sf.atomic?}
      atomic_formulas.each do |sf|
        tmp = @atomic_expansions[sf.formula.arg].clone
        tmp << sf.sign
        @atomic_expansions.merge!(Hash[sf.formula.arg, tmp])
        sf.expanded = true
      end
    end
  end

  class Generator
    attr_reader :root

    def initialize(formula)
      @formula = formula
      @root = Node.new(SignedFormula.new(formula, false, 1))
    end

    def generate!
      @root.expand_fully!
    end
  end

  def self.is_valid?(formula)
    generator = Generator.new(formula)
    generator.generate!
    generator.root.is_valid?
  end
end
