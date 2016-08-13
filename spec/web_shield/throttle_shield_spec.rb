module WebShield
  RSpec.describe ThrottleShield do
    let(:config) do
      double('config', {
        user_parser: Proc.new {|request| request.params['token'] },
        store: MemoryStore.new,
        logger: Logger.new('/dev/null')
      })
    end
    let(:shield) { build_shield('id1', '*') }
    let(:request) do
      Rack::Request.new(Rack::MockRequest.env_for('http://my.host.com/api/users'))
    end

    def build_shield(id, path, opts = {period: 3, limit: 3})
      ThrottleShield.new(id, path, opts, config)
    end

    describe '#filter' do
      it 'should return :pass, if request ok' do
        expect(shield.filter(request)).to eql(:pass)

        shield = build_shield('id1', '*', period: 3, limit: 3, method: :get)
        expect(shield.filter(request)).to eql(:pass)

        shield = build_shield('id2', '*', period: 3, limit: 3, method: 'GET')
        expect(shield.filter(request)).to eql(:pass)
      end

      it 'should return :pass, if no limit of method' do
        allow(request).to receive(:request_method).and_return('POST')
        expect(shield.filter(request)).to eql(:pass)

        allow(request).to receive(:request_method).and_return('DELETE')
        expect(shield.filter(request)).to eql(:pass)

        allow(request).to receive(:request_method).and_return('HEAD')
        expect(shield.filter(request)).to eql(:pass)
      end

      it 'should return nil when path no match' do
        expect(shield.path_matcher).to receive(:match).and_return(false)
        expect(shield.filter(request)).to eql(nil)
      end

      it 'should return nil when request method no match' do
        shield = build_shield('id1', '*', period: 3, limit: 1, method: :post)
        expect(shield.filter(request)).to eql(nil)
      end

      it 'should return :block when limit eql 0' do
        shield = build_shield('idx', '*', period: 3, limit: 0)
        expect(shield.filter(request)).to eql(:block)
      end

      it 'should block if request times > limit' do
        shield = build_shield('id1', '*', period: 0, limit: 1)

        expect(shield.filter(request)).to eql(:pass)
        expect(shield.filter(request)).to eql(:block)
        allow(request).to receive(:path).and_return('/another/path')
        expect(shield.filter(request)).to eql(:block)
        allow(request).to receive(:request_method).and_return('POST')
        expect(shield.filter(request)).to eql(:block)
      end

      it 'should not block another shield if request times > limit' do
        shield = build_shield('id1', '*', period: 0, limit: 1)
        shield2 = build_shield('id2', '*', period: 0, limit: 1)
        shield3 = build_shield('id1', '*', period: 0, limit: 1)

        expect(shield.filter(request)).to eql(:pass)
        expect(shield.filter(request)).to eql(:block)
        expect(shield2.filter(request)).to eql(:pass)
        expect(shield3.filter(request)).to eql(:block)
      end

      it 'should not block another path if path_sensitive' do
        shield = build_shield('id1', '*', period: 0, limit: 1, path_sensitive: true)

        expect(shield.filter(request)).to eql(:pass)
        expect(shield.filter(request)).to eql(:block)
        allow(request).to receive(:path).and_return('/another/path')
        expect(shield.filter(request)).to eql(:pass)
      end

      it 'should not block another request method if path_sensitive' do
        shield = build_shield('id1', '*', period: 0, limit: 1, path_sensitive: true)

        expect(shield.filter(request)).to eql(:pass)
        expect(shield.filter(request)).to eql(:block)
        allow(request).to receive(:request_method).and_return('POST')
        expect(shield.filter(request)).to eql(:pass)
      end
    end
  end
end
