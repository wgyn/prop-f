require_relative 'formula'

class TableauProver
  SignedFormula = Struct.new(:formula, :sign)

  # Represent a tableau as a list containing lists of SignedFormulas
  # TODO: Should instead make it a tree to display falsified models
  def self.closed?(tableau)
    if tableau == []
      return true
    end

    expanded = expand(tableau)
    return false if expanded == tableau
    filtered = remove_closed_branches(expanded)
    closed?(filtered)
  end

  def self.expand(tableau)
    tableau.map do |branch|
      branch.map do |signed_formula|
        formula = signed_formula.formula
        sign = signed_formula.sign

        if formula.class == Formula::Not
          SignedFormula.new(formula.arg, !sign)
        elsif formula.class == Formula::And && sign == true
          [
            SignedFormula.new(formula.arg1, true),
            SignedFormula.new(formula.arg2, true),
          ]
        elsif formula.class == Formula::Or && sign == false
          [
            SignedFormula.new(formula.arg1, false),
            SignedFormula.new(formula.arg2, false),
          ]
        elsif formula.class == Formula::Implies && sign == false
          [
            SignedFormula.new(formula.arg1, true),
            SignedFormula.new(formula.arg2, false),
          ]
        else
          signed_formula
        end
        # TODO: Handle disjunctive expansions
      end.flatten
    end
  end

  def self.remove_closed_branches(tableau)
    tableau.reject do |branch|
      !branch.select { |sf| sf.formula.atomic? && sf.sign }.empty? &&
        !branch.select { |sf| sf.formula.atomic? && !sf.sign }.empty?
    end
  end

  def self.is_valid?(formula)
    self.closed?([[SignedFormula.new(formula, false)]])
  end
end
