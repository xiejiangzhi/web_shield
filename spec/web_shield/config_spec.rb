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
        args = ['/api/*', preiod: 1, limit: 2]
        expect {
          config.build_shield(*args)
          config.build_shield(*args)
        }.to change(config.shields, :count).by(2)

        expect(config.shields.last).to eq(args + [nil])
      end

      it 'should raise error, invalid args' do
        expect {
          expect {
            config.build_shield '/api/*'
          }.to raise_error(Error, 'Need options or block')
        }.to_not change(config.shields, :count)
      end
    end

    describe '#use' do
      it 'should add plugin' do
        plugin = double('plugin', new: true)
        plugin2 = double('plugin2', new: true)

        expect {
          config.use(plugin)
          config.use(plugin)
          config.use(plugin2, a: 1)
        }.to change(config.plugins, :count).by(2)

        expect(config.plugins.last).to eq([plugin2, {a: 1}, nil])
      end

      it 'should raise error, invalid args' do
        expect {
          expect {
            config.use double('invalid-plugin')
          }.to raise_error(Error, 'Need a plugin class')
        }.to_not change(config.plugins, :count)
      end
    end
  end
end

