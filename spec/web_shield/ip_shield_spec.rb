module WebShield
  RSpec.describe IPShield do
    let(:config) do
      double('config', {
        user_parser: Proc.new {|request| request.params['token'] },
        store: MemoryStore.new,
        logger: Logger.new('/dev/null')
      })
    end
    let(:shield) { build_shield('id1', '*') }
    let(:request) do
      env = Rack::MockRequest.env_for('http://my.host.com/api/users')
      env['REMOTE_ADDR'] = '127.0.0.1'
      Rack::Request.new(env)
    end

    def build_shield(id, path, opts = {})
      IPShield.new(id, path, opts, config)
    end

    describe '#initialize' do
      it 'should push options[:whitelist] to whitelist' do
        expect_any_instance_of(IPShield).to receive(:push_to_whitelist).with(['127.0.0.1'])
        build_shield('id2', '*', whitelist: %w{127.0.0.1}, blacklist: %w{111.1.1.1})
      end

      it 'should push options[:blacklist] to blacklist' do
        expect_any_instance_of(IPShield).to receive(:push_to_blacklist).with(['111.1.1.1'])
        build_shield('id2', '*', whitelist: %w{127.0.0.1}, blacklist: %w{111.1.1.1})
      end
    end

    describe '#dictatorial?' do
      it 'should return true' do
        expect(shield.dictatorial?).to eql(true)
      end
    end

    describe '#filter' do
      it 'should return nil if not in whitelist and blacklist' do
        expect(shield.filter(request)).to eql(nil)
      end

      it 'should return :pass if in whitelist and blacklist' do
        expect(shield).to receive(:in_whitelist?).with('127.0.0.1').and_return(true)
        expect(shield.filter(request)).to eql(:pass)
      end

      it 'should return :block if in whitelist and blacklist' do
        expect(shield).to_not receive(:in_whitelist?)
        expect(shield).to receive(:in_blacklist?).with('127.0.0.1').and_return(true)
        expect(shield.filter(request)).to eql(:block)
      end

      it 'should return :block if in blacklist' do
        allow(shield).to receive(:in_blacklist?).and_return(true)
        expect(shield.filter(request)).to eql(:block)
      end
    end

    describe '#in_whitelist?' do
      before :each do
        shield.push_to_whitelist(%w{127.0.0.1 192.168.0.0/16})
      end

      it 'should return true, if ip in whitelist' do
        expect(shield.in_whitelist?('127.0.0.1')).to eq(true)
        expect(shield.in_whitelist?('192.168.0.1')).to eq(true)
        expect(shield.in_whitelist?('192.168.123.1')).to eq(true)
        expect(shield.in_whitelist?('192.168.254.254')).to eq(true)
      end

      it 'should return false, if ip out whitelist' do
        expect(shield.in_whitelist?('127.0.0.2')).to eq(false)
        expect(shield.in_whitelist?('192.167.0.1')).to eq(false)
        expect(shield.in_whitelist?('193.168.10.20')).to eq(false)
        expect(shield.in_whitelist?('192.169.10.20')).to eq(false)
      end

      it 'should not affect blacklist' do
        expect(shield.in_blacklist?('127.0.0.1')).to eq(false)
        expect(shield.in_blacklist?('127.0.0.2')).to eq(false)
        expect(shield.in_blacklist?('192.168.0.1')).to eq(false)
      end
    end

    describe '#in_blacklist?' do
      before :each do
        shield.push_to_blacklist(%w{127.0.0.2 111.10.2.0/24})
      end

      it 'should return true, if ip in blacklist' do
        expect(shield.in_blacklist?('127.0.0.2')).to eq(true)
        expect(shield.in_blacklist?('111.10.2.1')).to eq(true)
        expect(shield.in_blacklist?('111.10.2.254')).to eq(true)
      end

      it 'should return false, if ip out blacklist' do
        expect(shield.in_blacklist?('127.0.0.1')).to eq(false)
        expect(shield.in_blacklist?('111.10.1.1')).to eq(false)
        expect(shield.in_blacklist?('111.10.3.10')).to eq(false)
        expect(shield.in_blacklist?('111.11.2.1')).to eq(false)
      end

      it 'should not affect blacklist' do
        expect(shield.in_whitelist?('127.0.0.1')).to eq(false)
        expect(shield.in_whitelist?('111.10.1.1')).to eq(false)
        expect(shield.in_whitelist?('111.10.3.10')).to eq(false)
        expect(shield.in_whitelist?('111.11.2.1')).to eq(false)
      end
    end
  end
end
