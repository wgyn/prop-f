require 'minitest/autorun'

require_relative 'checker'

describe Checker do
  before do
    @checker = Checker.new
  end

  describe '#evaluate' do
    [
      [true, 'p || !p'],
      [true, '!(q && r) -> (!q || !r)'],
    ].each do |expected, expression|
      it "correctly evaluates to #{expected}: #{expression}" do
        assert_equal(expected, @checker.evaluate(expression))
      end
    end
  end
end
