module WebShield
  RSpec.describe Shield do
    let(:config) do
      double('config', {
        user_parser: Proc.new {|request| request.params['token'] },
        store: MemoryStore.new
      })
    end
    let(:shield) { build_shield('id1', '*') }
    let(:request) do
      Rack::Request.new(Rack::MockRequest.env_for('http://my.host.com/api/users'))
    end

    def build_shield(id, path, opts = {period: 3, limit: 3})
      Shield.new(id, path, opts, config)
    end

    describe '#id' do
      it 'should use init argument' do
        expect(shield.id).to eql('id1')
      end
    end

    describe '#shield_path' do
      it 'should use init argument' do
        expect(shield.shield_path).to eql('*')
      end
    end

    describe '#path_matcher' do
      def test_path_matcher(path, regexp)
        expect(build_shield('id1', path).path_matcher).to eql(regexp)
      end

      it 'should build string regexp' do
        test_path_matcher('/', %r{\A/?\z}i)
        test_path_matcher('/api', %r{\A/api\z}i)
        test_path_matcher('/api/v1/', %r{\A/api/v1/?\z}i)
      end

      it 'should build :name regexp' do
        test_path_matcher('/:ver', %r{\A/[^/]+\z}i)
        test_path_matcher('/api/:ver', %r{\A/api/[^/]+\z}i)
        test_path_matcher('/api/:ver/user', %r{\A/api/[^/]+/user\z}i)
      end

      it 'should build () regexp' do
        test_path_matcher('/(v1)', %r{\A/(v1)?\z}i)
        test_path_matcher('/api/(v1)', %r{\A/api/(v1)?\z}i)
        test_path_matcher('/api(/v1)', %r{\A/api(/v1)?\z}i)
        test_path_matcher('/api(/v1)/user', %r{\A/api(/v1)?/user\z}i)
      end

      it 'should build * regexp' do
        test_path_matcher('*', %r{\A.*\z}i)
        test_path_matcher('/*', %r{\A/.*\z}i)
        test_path_matcher('/api/*', %r{\A/api/.*\z}i)
        test_path_matcher('/api/*/users', %r{\A/api/.*/users\z}i)
      end

      it 'should build mixed regexp' do
        test_path_matcher('/api/:ver/*', %r{\A/api/[^/]+/.*\z}i)
        test_path_matcher('/api/(:ver)/*', %r{\A/api/([^/]+)?/.*\z}i)
        test_path_matcher('/api/a-(:ver)-b/:name/*', %r{\A/api/a\-([^/]+)?\-b/[^/]+/.*\z}i)
      end
    end

    describe '#options' do
      it 'should use symbol keys' do
        expect(shield.options).to eql(period: 3, limit: 3)
        shield2 = build_shield('id', '*', 'period' => 3, 'limit' => 1)
        expect(shield2.options).to eql(period: 3, limit: 1)
      end

      it 'should raise error if have invalid keys' do
        expect {
          build_shield('id', '*', 'period' => 3, 'limit' => 1, test: 1)
        }.to raise_error(Error, 'Invalid shield option \'test\'')
      end
    end

    describe '#config' do
      it 'should use init argument' do
        expect(shield.config).to eql(config)
      end
    end

    describe '#dictatorial?' do
      it 'should return options[:dictatorial]' do
        shield.options[:dictatorial] = true
        expect(shield.dictatorial?).to eql(true)

        shield.options[:dictatorial] = false
        expect(shield.dictatorial?).to eql(false)
      end
    end
  end
end
