require 'minitest/autorun'

require_relative 'formula'
require_relative 'tableau_prover'

describe Tableau do
  before do
    @p = Formula::Atom.new('p')
    @q = Formula::Atom.new('q')
    @r = Formula::Atom.new('r')
  end

  def assert_valid_formulas(formulas)
    formulas.each do |f|
      assert(Tableau.is_valid?(f), "#{f} should have been valid!")
    end
  end

  def assert_invalid_formulas(formulas)
    formulas.each do |f|
      refute(Tableau.is_valid?(f), "#{f} should have been invalid!")
    end
  end

  describe '#is_valid?' do
    it 'invalidates single-variable formulas' do
      assert_invalid_formulas([@p, Formula.not(@p)])
    end

    describe 'two-variable formulas' do
      it 'correctly validates simple non-disjunctive formulas' do
        assert_valid_formulas([
          Formula.or(@p, Formula.not(@p)),
          Formula.implies(@p, @p),
        ])
      end

      it 'correctly invalidates simple non-disjunctive formulas' do
        assert_invalid_formulas([
          Formula.and(@p, Formula.not(@p)),
          Formula.and(@p, @q),
          Formula.or(@p, @q),
          Formula.not(Formula.and(@p, @q)),
        ])
      end

      it 'correctly validates simple disjunctive formulas' do
        assert_valid_formulas([
          # !(p && q) => (!p || !q)
          Formula.implies(
            Formula.not(Formula.and(@p, @q)),
            Formula.or(Formula.not(@p), Formula.not(@q)),
          ),
        ])
      end
    end
  end
end
