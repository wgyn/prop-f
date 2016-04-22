require 'minitest/autorun'

require_relative 'formula'
require_relative 'tableau_prover'

describe TableauProver do
  before do
    @p = Formula::Atom.new('p')
    @q = Formula::Atom.new('q')
  end

  describe '#is_valid?' do
    it 'validates the truth of simple non-disjunctive formulas' do
      [
        [false, @p],
        [false, Formula.not(@p)],
        [true, Formula.or(@p, Formula.not(@p))],
        [false, Formula.and(@p, Formula.not(@p))],
        [false, Formula.and(@p, Formula.not(@q))],
        [false, Formula.not(Formula.and(@p, @q))],
      ].each do |expected, formula|
        assert_equal(expected, TableauProver.is_valid?(formula))
      end
    end
  end
end
