require_relative 'formula'

module Resolution
  module Conversions

    def self.simplify(formula)
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
        Formula.or(Formula.not(p), q)
      when Formula::And
        Formula.and(
          self.simplify(formula.arg1),
          self.simplify(formula.arg2),
        )
      when Formula::Or
        Formula.or(
          self.simplify(formula.arg1),
          self.simplify(formula.arg2),
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
        formula = self.simplify(formula)
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
  end
end
