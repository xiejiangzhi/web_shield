module WebShield
  RSpec.describe CreditShield do
    let(:config) do
      double('config', {
        user_parser: Proc.new {|request| request.params['token'] || 'uid' },
        store: MemoryStore.new,
        logger: Logger.new('/dev/null')
      })
    end
    let(:shield) { build_shield('id1', '*', default_user_credit: 3, default_ip_credit: 5) }
    let(:request) do
      env = Rack::MockRequest.env_for('http://my.host.com/api/users?a=1')
      env['REMOTE_ADDR'] = '127.0.0.1'
      Rack::Request.new(env)
    end

    def build_shield(id, path, opts = {})
      CreditShield.new(id, path, opts, config)
    end

    describe '#filter' do
      it 'should return :pass, if valid request' do
        expect(shield).to receive(:check_request).with('127.0.0.1', 'uid').and_return(true)
        expect(shield.filter(request)).to eql(:pass)
      end

      it 'should return :block, if invalid request' do
        expect(shield).to receive(:check_request).with('127.0.0.1', 'uid').and_return(false)
        expect(shield.filter(request)).to eql(:block)
      end

      it 'should call CreditAnalyzer#analyze' do
        expect(CreditAnalyzer).to receive(:analyze).with('127.0.0.1', 'uid', {}, {'a' => '1'})
        shield.filter(request)
        sleep 0.2
      end
    end

    describe '#check_request' do
      before :each do
        travel_to Time.now
      end

      it 'should return true if user credit >= requests total' do
        3.times { expect(shield.check_request('1.1.1.1', 'user')).to eql(true) }
      end

      it 'should return false if user credit < requests total' do
        3.times { expect(shield.check_request('1.1.1.1', 'user')).to eql(true) }
        expect(shield.check_request('1.1.1.1', 'user')).to eql(false)
        expect(shield.check_request('1.1.1.2', 'user')).to eql(false)
        expect(shield.check_request('1.1.1.1', 'user2')).to eql(true)
        expect(shield.check_request('1.1.1.3', 'user2')).to eql(true)
      end

      it 'should return false if ip credit < requests total' do
        5.times { expect(shield.check_request('1.1.1.1', nil)).to eql(true) }
        expect(shield.check_request('1.1.1.1', nil)).to eql(false)
        expect(shield.check_request('1.1.1.1', 'user1')).to eql(false)
        expect(shield.check_request('1.1.1.1', 'user2')).to eql(false)

        expect(shield.check_request('1.1.1.2', 'user2')).to eql(true)
        expect(shield.check_request('1.1.1.2', nil)).to eql(true)
      end

      it 'should ignore user if user is nil' do
        3.times { expect(shield.check_request('1.1.1.1', 'user')).to eql(true) }
        expect(shield.check_request('1.1.1.1', nil)).to eql(true)
      end

      it 'should ignore ip if ip is nil' do
        3.times { expect(shield.check_request(nil, 'user')).to eql(true) }
        3.times { expect(shield.check_request(nil, 'user2')).to eql(true) }
        3.times { expect(shield.check_request(nil, 'user3')).to eql(true) }
        expect(shield.check_request('1.1.1.1', 'user4')).to eql(true)
      end

      it 'should return true if user and ip is nil' do
        10.times { expect(shield.check_request(nil, nil)).to eql(true) }
      end

      it 'should return false if ip request > store credit' do
        config.store.set(shield.send(:get_credit_key, :ip, '1.1.1.1'), 1)
        expect(shield.check_request('1.1.1.1', 'user1')).to eql(true)
        expect(shield.check_request('1.1.1.1', 'user2')).to eql(false)
        expect(shield.check_request('1.1.1.2', 'user')).to eql(true)

        config.store.set(shield.send(:get_credit_key, :ip, '1.1.1.11'), 0)
        expect(shield.check_request('1.1.1.11', 'user3')).to eql(false)
        expect(shield.check_request('1.1.1.11', 'user4')).to eql(false)
        expect(shield.check_request('1.1.1.2', 'user5')).to eql(true)

        config.store.set(shield.send(:get_credit_key, :ip, '1.1.1.22'), -1)
        expect(shield.check_request('1.1.1.22', 'user6')).to eql(false)
        expect(shield.check_request(nil, 'user7')).to eql(true)
      end

      it 'should return false if user request > store credit' do
        config.store.set(shield.send(:get_credit_key, :u, 'user'), 1)
        expect(shield.check_request('1.1.1.1', 'user')).to eql(true)
        expect(shield.check_request('1.1.1.2', 'user')).to eql(false)
        expect(shield.check_request('1.1.1.2', 'user2')).to eql(true)

        config.store.set(shield.send(:get_credit_key, :u, 'user1'), 0)
        expect(shield.check_request(nil, 'user1')).to eql(false)
        expect(shield.check_request(nil, 'user2')).to eql(true)
        expect(shield.check_request('1.1.1.3', 'user1')).to eql(false)

        config.store.set(shield.send(:get_credit_key, :u, 'user5'), -1)
        expect(shield.check_request(nil, 'user5')).to eql(false)
        expect(shield.check_request(nil, 'user3')).to eql(true)
      end
    end
  end
end

