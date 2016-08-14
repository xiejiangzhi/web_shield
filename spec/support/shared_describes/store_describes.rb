RSpec.shared_examples 'store_describes' do |store_cls|
  describe "store" do
    let(:store) { store_cls.new }

    describe '#get/#set' do
      it 'should set key' do
        expect(store.set('a', 1)).to eq('1')
        expect(store.get('a')).to eq('1')

        expect(store.set('b', 'asdf')).to eq('asdf')
        expect(store.get('b')).to eq('asdf')

        expect(store.get('a')).to eq('1')

        expect(store.set('a', 'hello')).to eq('hello')
        expect(store.get('a')).to eq('hello')
      end

      it 'should expire data, if expire < current time' do
        t = Time.now
        expire_at = t + 10
        allow(Time).to receive(:now).and_return(t)

        expect(store.set('a', 'hello', expire_at: expire_at)).to eq('hello')
        expect(store.get('a')).to eq('hello')

        allow(Time).to receive(:now).and_return(t + 9)
        expect(store.get('a')).to eq('hello')

        allow(Time).to receive(:now).and_return(t + 10)
        expect(store.get('a')).to eq(nil)
        expect(store.get('a')).to eq(nil) # double check

        allow(Time).to receive(:now).and_return(t + 1123)
        expect(store.get('a')).to eq(nil)
      end
    end

    describe '#incr' do
      it 'should incr counter' do
        expect(store.incr('a')).to eq(1)
        expect(store.incr(:a)).to eq(2)
        expect(store.incr(:a, increment: 2)).to eq(4)

        expect(store.incr('b', increment: 10)).to eq(10)
        expect(store.incr('b')).to eq(11)
        expect(store.incr('a')).to eq(5)
      end

      it 'should expire old counter' do
        t = Time.now
        et = t + 10

        allow(Time).to receive(:now).and_return(t)
        expect(store.incr('a', expire_at: et)).to eq(1)
        expect(store.incr('a', expire_at: et)).to eq(2)
        expect(store.get('a')).to eq('2')
        expect(store.incr('b', expire_at: et - 5)).to eq(1)
        expect(store.incr('b', expire_at: et - 5)).to eq(2)
        expect(store.get('b')).to eq('2')

        allow(Time).to receive(:now).and_return(t + 5)
        expect(store.incr('a', expire_at: et)).to eq(3)
        expect(store.incr('a', expire_at: et)).to eq(4)
        expect(store.get('a')).to eq('4')
        expect(store.incr('b', expire_at: et - 5)).to eq(1)
        expect(store.incr('b', expire_at: et - 5)).to eq(1)
        expect(store.get('b')).to eq(nil)
      end

      it 'should not expire, if expire_at eql nil' do
        t = Time.now

        allow(Time).to receive(:now).and_return(t)
        expect(store.incr('a')).to eq(1)
        expect(store.incr('a')).to eq(2)

        allow(Time).to receive(:now).and_return(t + 1000000)
        expect(store.incr('a')).to eq(3)
        expect(store.incr('a')).to eq(4)
      end

      it 'should correct store when use multiple threads' do
        10.times.map {
          [Thread.new { store.incr('a') }, Thread.new { store.incr('b') }]
        }.flatten.map(&:join)
        %w{a b}.each {|key| expect(store.get(key)).to eql('10') }

        et = Time.now + 3
        10.times.map {
          [
            Thread.new { store.incr('c', expire_at: et) },
            Thread.new { store.incr('d', expire_at: et) }
          ]
        }.flatten.map(&:join)
        %w{c d}.each {|key| expect(store.incr(key)).to eql(11) }
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

    describe '#sadd' do
      it 'should add to set' do
        expect {
          store.sadd('a', 1)
          store.sadd(:a, 2)
        }.to change { store.smembers('a').length }.by(2)
        expect(store.smembers('a')).to eq(Set.new(['1', '2']))
      end

      it 'should add to set if give multiple values' do
        expect {
          store.sadd('a', [1, 2])
        }.to change { store.smembers('a').length }.by(2)
        expect(store.smembers(:a)).to eq(Set.new(['1', '2']))
      end

      it 'should correct store when use multiple threads' do
        10.times.map {|i|
          [Thread.new { store.sadd('a', i) }, Thread.new { store.sadd('b', [i]) }]
        }.flatten.map(&:join)
        %w{a b}.each {|key| expect(store.smembers(key)).to eql(Set.new(10.times.map(&:to_s))) }
      end
    end

    describe '#srem' do
      let(:vals) { (1..10).to_a }

      before :each do
        store.sadd('a', vals)
      end

      it 'should remove from set' do
        expect {
          store.srem('a', 2)
          store.srem(:a, ['4', 5])
          store.srem(:a, 123)
        }.to change { store.smembers('a').length }.by(-3)
        expect(store.smembers('a')).to eq(Set.new((vals - [2, 4, 5]).map(&:to_s)))
      end

      it 'should correct store when use multiple threads' do
        store.sadd('b', vals)
        10.times.map {|i|
          [Thread.new { store.srem('a', i) }, Thread.new { store.srem('b', [i]) }]
        }.flatten.map(&:join)
        %w{a b}.each {|key| expect(store.smembers(key)).to eql(Set.new(['10'])) }
      end
    end

    describe '#sismember' do
      before :each do
        store.sadd('s', ['a', 'b', 'd'])
      end

      it 'should return true when have member' do
        expect(store.sismember('s', 'a')).to eql(true)
        expect(store.sismember(:s, 'b')).to eql(true)
        expect(store.sismember('s', 'd')).to eql(true)
      end

      it 'should retrun false when not a member of the set' do
        expect(store.sismember('s', 'c')).to eql(false)
        expect(store.sismember('s', 'e')).to eql(false)
        expect(store.sismember(:s, 'easdf')).to eql(false)
      end

      it 'should return false when set not exist' do
        expect(store.sismember(:sss, 'easdf')).to eql(false)
      end
    end
  end
end
