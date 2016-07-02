require 'minitest/autorun'

require_relative 'formula'
require_relative 'resolution_prover'

describe Resolution do
  before do
    @p = Formula::Atom.new('p')
    @q = Formula::Atom.new('q')
    @r = Formula::Atom.new('r')
    @s = Formula::Atom.new('s')
  end

  describe 'Conversions' do
    describe '(!p -> q) -> (!r -> s)' do
      before do
        @formula = Formula.implies(
          Formula.implies(Formula.not(@p), @q),
          Formula.implies(Formula.not(@r), @s),
        )
        @formula_nnf = Formula.or(
          Formula.and(Formula.not(@p), Formula.not(@q)),
          Formula.or(@r, @s),
        )
        @formula_cnf = Formula.and(
          Formula.or(Formula.not(@p), Formula.or(@r, @s)),
          Formula.or(Formula.not(@q), Formula.or(@r, @s)),
        )
      end

      it 'correctly applies #negation_normal_form' do
        assert_equal(
          @formula_nnf.to_s,
          Resolution::Conversions.negation_normal_form(@formula).to_s,
        )
      end

      it 'correctly applies #negation_normal_form?' do
        assert(!Resolution::Conversions.negation_normal_form?(@formula))
        assert(Resolution::Conversions.negation_normal_form?(@formula_nnf))
      end
    end
  end
end