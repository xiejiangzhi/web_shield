RSpec.shared_examples 'store_describes' do |store_cls|
  describe "store" do
    let(:store) { store_cls.new }

    describe '#incr' do
      it 'should incr counter' do
        expect(store.incr('a')).to eq(1)
        expect(store.incr(:a)).to eq(2)
        expect(store.incr('b')).to eq(1)
        expect(store.incr('b')).to eq(2)
        expect(store.incr('a')).to eq(3)
      end

      it 'should expire old counter' do
        period = 6
        t = Time.at(Time.now.to_i / period * period)

        allow(Time).to receive(:now).and_return(t)
        expect(store.incr('a', period)).to eq(1)
        expect(store.incr('a', period)).to eq(2)
        expect(store.incr('b', period / 2)).to eq(1)
        expect(store.incr('b', period / 2)).to eq(2)

        allow(Time).to receive(:now).and_return(t + 3)
        expect(store.incr('a', period)).to eq(3)
        expect(store.incr('a', period)).to eq(4)
        expect(store.incr('b', period / 2)).to eq(1)
        expect(store.incr('b', period / 2)).to eq(2)

        allow(Time).to receive(:now).and_return(t + 4)
        expect(store.incr('a', period)).to eq(5)
        expect(store.incr('a', period)).to eq(6)
        expect(store.incr('b', period / 2)).to eq(3)
        expect(store.incr('b', period / 2)).to eq(4)
      end

      it 'should not expire, if period = 0' do
        t = Time.now

        allow(Time).to receive(:now).and_return(t)
        expect(store.incr('a', 0)).to eq(1)
        expect(store.incr('a', 0)).to eq(2)

        allow(Time).to receive(:now).and_return(t + 1000000)
        expect(store.incr('a', 0)).to eq(3)
        expect(store.incr('a', 0)).to eq(4)
      end

      it 'should correct store when use multiple threads' do
        10.times.map {
          [Thread.new { store.incr('a') }, Thread.new { store.incr('b') }]
        }.flatten.map(&:join)
        %w{a b}.each {|key| expect(store.incr(key)).to eql(11) }

        t = Time.now
        allow(Time).to receive(:now).and_return(t)
        10.times.map {
          [Thread.new { store.incr('c', 1) }, Thread.new { store.incr('d', 1) }]
        }.flatten.map(&:join)
        %w{c d}.each {|key| expect(store.incr(key, 1)).to eql(11) }
      end
    end

    describe '#reset' do
      it 'should delete specify key' do
        expect(store.incr('a')).to eq(1)
        expect(store.incr('b')).to eq(1)
        store.reset('a')
        expect(store.incr('a')).to eq(1)
        expect(store.incr('b')).to eq(2)
      end
    end

    describe '#clear' do
      it 'should delete all keys' do
        expect(store.incr('a')).to eq(1)
        expect(store.incr('b')).to eq(1)
        store.clear
        expect(store.incr('a')).to eq(1)
        expect(store.incr('b')).to eq(1)
      end
    end

    describe '#push_to_set' do
      it 'should add to set' do
        expect {
          store.push_to_set('a', 1)
          store.push_to_set('a', 2)
        }.to change { store.read_set('a').length }.by(2)
        expect(store.read_set('a')).to eq(Set.new(['1', '2']))
      end

      it 'should add to set if give multiple values' do
        expect {
          store.push_to_set('a', [1, 2])
        }.to change { store.read_set('a').length }.by(2)
        expect(store.read_set('a')).to eq(Set.new(['1', '2']))
      end

      it 'should correct store when use multiple threads' do
        10.times.map {|i|
          [Thread.new { store.push_to_set('a', i) }, Thread.new { store.push_to_set('b', [i]) }]
        }.flatten.map(&:join)
        %w{a b}.each {|key| expect(store.read_set(key)).to eql(Set.new(10.times.map(&:to_s))) }
      end
    end

    describe '#del_to_list' do
      let(:vals) { (1..10).to_a }

      before :each do
        store.push_to_set('a', vals)
      end

      it 'should remove from set' do
        expect {
          store.del_from_set('a', 2)
          store.del_from_set('a', [4, 5])
        }.to change { store.read_set('a').length }.by(-3)
        expect(store.read_set('a')).to eq(Set.new((vals - [2, 4, 5]).map(&:to_s)))
      end

      it 'should correct store when use multiple threads' do
        store.push_to_set('b', vals)
        10.times.map {|i|
          [Thread.new { store.del_from_set('a', i) }, Thread.new { store.del_from_set('b', [i]) }]
        }.flatten.map(&:join)
        %w{a b}.each {|key| expect(store.read_set(key)).to eql(Set.new(['10'])) }
      end
    end
  end
end
