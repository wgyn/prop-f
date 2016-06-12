require 'minitest/autorun'

require_relative 'formula'
require_relative 'tableau_prover'

describe Tableau do
  before do
    @p = Formula::Atom.new('p')
    @q = Formula::Atom.new('q')
    @r = Formula::Atom.new('r')

    @p_and_q = Formula.and(@p, @q)
    @p_or_q = Formula.or(@p, @q)
    @p_or_r = Formula.or(@p, @r)
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

    describe 'one-variable formulas' do
      it 'correctly validates non-disjunctive formulas' do
        assert_valid_formulas([
          Formula.or(@p, Formula.not(@p)),
          Formula.implies(@p, @p),
        ])
      end

      it 'correctly invalidates non-disjunctive formulas' do
        assert_invalid_formulas([
          Formula.and(@p, Formula.not(@p)),
        ])
      end
    end

    describe 'two-variable formulas' do
      it 'correctly validates non-disjunctive formulas' do
        assert_valid_formulas([])
      end

      it 'correctly invalidates non-disjunctive formulas' do
        assert_invalid_formulas([
          Formula.and(@p, @q),
          Formula.or(@p, @q),
          Formula.not(@p_and_q),
        ])
      end

      it 'correctly validates disjunctive formulas' do
        assert_valid_formulas([
          # !(p && q) => (!p || !q)
          Formula.implies(
            Formula.not(@p_and_q),
            Formula.or(Formula.not(@p), Formula.not(@q)),
          ),
        ])
      end

      it 'correctly invalidates disjunctive formulas' do
        assert_invalid_formulas([])
      end
    end

    describe 'three-variable formulas' do
      it 'correctly validates disjunctive formulas' do
        assert_valid_formulas([
          # (p || (q && r)) -> ((p || q) && (p || r))
          Formula.implies(
            Formula.or(@p, Formula.and(@q, @r)),
            Formula.and(@p_or_q, @p_or_r),
          ),
        ])
      end

      it 'correctly validates disjunctive formulas' do
        assert_invalid_formulas([
          # (p || q || r) -> ((p || q) && (p || r))
          Formula.implies(
            Formula.or(@p_or_q, @r),
            Formula.and(@p_or_q, @p_or_r),
          ),
        ])
      end
    end
  end
end
