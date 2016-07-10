module WebShield
  RSpec.describe Middleware do
    let(:shield1) { double('shield', filter: :pass, dictatorial?: false) }
    let(:shield2) { double('shield2', filter: :pass, dictatorial?: false) }
    let(:blocked_res) { Proc.new {|req| 'blocked' } }
    let(:config) { double('config', shields: [shield1, shield2], blocked_response: blocked_res) }
    let(:app) { Proc.new {|env| 'ok' } }
    let(:middleware) { Middleware.new(app, config) }
    let(:req_env) { Rack::MockRequest.env_for('http://asdf.com') }

    describe '#call' do
      it 'should call shields' do
        expect(shield1).to receive(:filter).and_return(:pass)
        expect(shield2).to receive(:filter).and_return(:pass)
        expect(app).to receive(:call).and_call_original
        expect(middleware.call(req_env)).to eql('ok')
      end

      it 'should not call shield2 if shield1 blocked' do
        expect(shield1).to receive(:filter).and_return(:block)
        expect(shield2).to_not receive(:filter)
        expect(app).to_not receive(:call)
        expect(blocked_res).to receive(:call).and_call_original
        expect(middleware.call(req_env)).to eql('blocked')
      end

      it 'should not call shield2 if shield1 is dictatorial' do
        allow(shield1).to receive(:dictatorial?).and_return(true)
        expect(shield2).to_not receive(:filter)
        expect(app).to receive(:call).and_call_original
        expect(middleware.call(req_env)).to eql('ok')

        allow(shield1).to receive(:dictatorial?).and_return(true)
        allow(shield1).to receive(:filter).and_return(:block)
        expect(shield2).to_not receive(:filter)
        expect(app).to_not receive(:call)
        expect(blocked_res).to receive(:call).and_call_original
        expect(middleware.call(req_env)).to eql('blocked')
      end

      it 'should use shield response, if shield return :response' do
        allow(shield1).to receive(:filter).and_return([:response, 'shield_res'])
        expect(shield2).to_not receive(:filter)
        expect(app).to_not receive(:call)
        expect(blocked_res).to_not receive(:call)
        expect(middleware.call(req_env)).to eql('shield_res')
      end

      it 'should ignore, if shield return other' do
        expect(shield1).to receive(:filter).and_return(nil)
        expect(shield2).to receive(:filter).and_return(:asdf)
        expect(app).to receive(:call).and_call_original
        expect(blocked_res).to_not receive(:call)
        expect(middleware.call(req_env)).to eql('ok')
      end
    end
  end
end

