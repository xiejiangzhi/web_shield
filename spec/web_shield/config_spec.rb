module WebShield
  RSpec.describe Config do
    let(:config) { Config.new }

    describe '#store=' do
      it 'should read/write store' do
        store = double('store', incr: 1)
        store2 = double('store2', incr: 2)
        config.store = store
        expect(config.store).to eq(store)

        config.store = store2
        expect(config.store).to eq(store2)
      end

      it 'should raise error if invalid store' do
        expect {
          config.store = 'invalid store'
        }.to raise_error(Error, /^Invalid store/)
      end
    end

    describe '#user_parser=' do
      it 'should read/write user_parser' do
        parser = Proc.new {|req| req.user }
        config.user_parser = parser
        expect(config.user_parser).to eq(parser)

        config.user_parser = parser
        expect(config.user_parser).to eq(parser)
      end

      it 'should raise error if invalid parser' do
        expect {
          config.user_parser = "invalid parser"
        }.to raise_error(Error, /^Invalid parser/)
      end
    end

    describe '#build_shield' do
      it 'should add shield' do
        t = Time.now
        allow(Time).to receive(:now).and_return(t)

        args = ['/api/*', period: 1, limit: 2]
        expect {
          config.build_shield(*args)
          config.build_shield(*args)
        }.to change(config.shields, :count).by(2)

        shield = config.shields.last
        expect(shield).to be_is_a(ThrottleShield)
        expect(shield.options).to eql(period: 1, limit: 2)
        expect(config.shields[0].id).to eql("#{t.to_f}-1")
        expect(config.shields[1].id).to eql("#{t.to_f}-2")
      end

      it 'should return shield' do
        shield = config.build_shield('*', period: 2, limit: 3)
        expect(shield).to be_a(ThrottleShield)
        expect(shield.options).to eql(period: 2, limit: 3)
      end
    end
  end
end

