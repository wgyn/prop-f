require_relative 'formula'

module Resolution
  module Conversions

    # TODO: Convert it back to a formula object
    class SetCNFFormula
      attr_accessor :clauses

      def initialize
        @clauses = []
      end

      def self.from_formula(formula)
        return unless \
          Resolution::Conversions.conjunctive_normal_form?(formula)

        cnf = self.new
        current = formula

        loop do
          if Resolution::Conversions::Clause.is_clause?(current)
            cnf.clauses << Resolution::Conversions::Clause.from_formula(current)
            break
          elsif current.is_a?(Formula::And)
            cnf.clauses << Resolution::Conversions::Clause.from_formula(current.arg1)
            current = current.arg2
          else
            # TODO: Should not need this assertion...
            raise RuntimeError.new "#{formula} is not in CNF!"
          end
        end

        cnf.clauses.uniq!
        cnf
      end
    end

    # TODO: Convert it back to a Formula object
    class Clause
      attr_accessor :literals

      def initialize
        @literals = []
      end

      def self.from_formula(formula)
        return unless self.is_clause?(formula)

        clause = self.new
        current = formula

        loop do
          if Resolution::Conversions.is_literal?(current)
            clause.literals << current
            break
          elsif current.is_a?(Formula::Or)
            clause.literals << current.arg1
            current = current.arg2
          else
            # TODO: Should not need this assertion...
            raise RuntimeError.new "#{formula} is not a clause!"
          end
        end

        clause.literals.uniq!
        clause
      end

      def ==(o); self.class == o.class && @literals == o.literals; end
      def hash; @literals.hash; end
      alias_method :eql?, :==
    end

    def self.nnf_simplify(formula)
      return formula if self.negation_normal_form?(formula)

      case formula
      when Formula::Not
        case formula.arg
        when Formula::And
          # !(p && q) simplifies to !p || !q
          p = formula.arg.arg1
          q = formula.arg.arg2
          Formula.or(Formula.not(p), Formula.not(q))
        when Formula::Or
          # !(p || q) simplifies to !p && !q
          p = formula.arg.arg1
          q = formula.arg.arg2
          Formula.and(Formula.not(p), Formula.not(q))
        when Formula::Implies
          # !(p -> q) simplifies to p && !q
          p = formula.arg.arg1
          q = formula.arg.arg2
          Formula.and(p, Formula.not(q))
        when Formula::Not
          # !!p simplifies to p
          formula.arg.arg
        end
      when Formula::Implies
        # p -> q simplifies to !p || q
        p = formula.arg1
        q = formula.arg2
      when Formula::And
        Formula.and(
          self.nnf_simplify(formula.arg1),
          self.nnf_simplify(formula.arg2),
        )
      when Formula::Or
        Formula.or(
          self.nnf_simplify(formula.arg1),
          self.nnf_simplify(formula.arg2),
        )
      when Formula::Atom
        formula
      end
    end

    # A formula is in Negation Normal Form (NNF) if || and && are the only
    # binary boolean connectives it contains, and every occurrence of a
    # negation symbol is applied to a sentence symbol.
    #
    # @param formula [Formula]
    # @returns [Formula]
    def self.negation_normal_form(formula)
      while !self.negation_normal_form?(formula)
        formula = self.nnf_simplify(formula)
      end

      formula
    end

    # A formula is in Negation Normal Form (NNF) if || and && are the only
    # binary boolean connectives it contains, and every occurrence of a
    # negation symbol is applied to a sentence symbol.
    def self.negation_normal_form?(formula)
      case formula
      when Formula::And, Formula::Or
        self.negation_normal_form?(formula.arg1) &&
          self.negation_normal_form?(formula.arg2)
      when Formula::Not
        return formula.arg.is_a?(Formula::Atom)
      when Formula::Atom
        return true
      else
        return false
      end
    end

    def self.cnf_simplify(formula)
      return formula if self.conjunctive_normal_form?(formula)

      simplified = case formula
      when Formula::Or
        # Converts (p || (q && r)) to ((p || q) && (q || r))
        if formula.arg2.is_a?(Formula::And)
          p = formula.arg1
          q = formula.arg2.arg1
          r = formula.arg2.arg2
          Formula.and(Formula.or(p, q), Formula.or(q, r))
        # Converts ((p && q) || r) to ((p || r) && (q || r))
        elsif formula.arg1.is_a?(Formula::And)
          p = formula.arg1.arg1
          q = formula.arg1.arg2
          r = formula.arg2
          Formula.and(Formula.or(p, r), Formula.or(q, r))
        # Converts ((p || q) || r) to (p || (q || r))
        elsif formula.arg1.is_a?(Formula::Or)
          p = formula.arg1.arg1
          q = formula.arg1.arg2
          r = formula.arg2
          Formula.or(p, Formula.or(q, r))
        end
      when Formula::And
        if formula.arg1.is_a?(Formula::And)
          p = formula.arg1.arg1
          q = formula.arg1.arg2
          r = formula.arg2
          Formula.and(p, Formula.and(q, r))
        end
      end

      simplified || formula
    end

    # A formula is in Conjunctive Normal Form (CNF) if and only if it is
    # a conjunction of clauses. A clause is a disjunction of atoms.
    def self.conjunctive_normal_form(formula)
      formula = self.negation_normal_form(formula)

      while !self.conjunctive_normal_form?(formula)
        formula = self.cnf_simplify(formula)
      end

      formula
    end

    def self.conjunctive_normal_form?(formula)
      if self.is_clause?(formula)
        true
      elsif formula.is_a?(Formula::And)
        self.conjunctive_normal_form?(formula.arg1) &&
          self.conjunctive_normal_form?(formula.arg2)
      else
        false
      end
    end

    # A clause is a disjunction of literals.
    def self.is_clause?(formula)
      if self.is_literal?(formula)
        true
      elsif formula.is_a?(Formula::Or)
        self.is_clause?(formula.arg1) && self.is_clause?(formula.arg2)
      else
        false
      end
    end

    # A literal is an atom or a negated atom.
    def self.is_literal?(formula)
      if formula.atomic?
        true
      elsif formula.is_a?(Formula::Not)
        formula.arg.atomic?
      else
        false
      end
    end
  end
end
