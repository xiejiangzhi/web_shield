module WebShield
  RSpec.describe MemoryStore do
    let(:store) { MemoryStore.new }

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

      it 'should correct when multiple threads' do
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
  end
end

