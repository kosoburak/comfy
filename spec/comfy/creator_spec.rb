require_relative '../spec_helper'

describe Comfy::Creator do
  let(:logger) { Logger.new(STDERR) }
  let(:creator) { Comfy::Creator.new({}, logger) }

  describe '.password' do
    it 'returns different 100 chars long passwords' do
      pwds = []
      30.times do
        pwd = creator.password
        expect(pwd.length).to eq(100)
        pwds << pwd
      end
      expect(pwds.length).to eq(pwds.uniq.length)
    end
  end

  describe '.get_group' do
    context "when group_dir doesn't exist" do
      it "should return [] if group_dir doesn't exist" do
        allow(Dir).to receive(:exist?).and_return(false)
        expect(creator.get_group('a', 'b', 'c')).to eq([])
      end
    end

    context 'with standard set of entries' do
      it 'should ignore . .. entries' do
        entries = ['qds', 'file.a', '..', 'e', 'something', '.', 'f']
        allow(Dir).to receive(:exist?).and_return(true)

        allow(Dir).to receive(:new).and_return(entries)
        allow(entries).to receive(:entries).and_return(entries)
        allow(entries).to receive(:path).and_return('path')

        entries_expected = entries.select { |x| x != '..' && x != '.' }.map { |x| "path/#{x}" }
        expect(creator.get_group('a', 'b', 'c')).to eq(entries_expected)
      end
    end

    context 'with no entries' do
      it 'should return []' do
        entries = ['.', '..']
        allow(Dir).to receive(:exist?).and_return(true)

        allow(Dir).to receive(:new).and_return(entries)
        allow(entries).to receive(:entries).and_return(entries)
        allow(entries).to receive(:path).and_return('path')

        entries_expected = entries.select { |x| x != '..' && x != '.' }.map { |x| "path/#{x}" }
        expect(creator.get_group('a', 'b', 'c')).to eq(entries_expected)
      end
    end
  end

  describe '.choose_version' do
    # it's okay to assume the JSON file is well-formed, otherwise
    # the whole thing would crash while parsing it, however
    # no assumptions can be made about the contents of the file (saved in desc)

    let(:options) { { distribution: 'any_distro', server_dir: 'any_dir' } }
    subject {creator.send(:choose_version)}

    # parameter: arr of version strings such as "14.5.2"
    # returns: string of available versions
    def create_versions(arr)
      versions = []
      arr.each do |version_string|
        entry = {}
        version_parts = version_string.split('.')
        entry['major_version'] = version_parts[0] if version_parts.size >= 1
        entry['minor_version'] = version_parts[1] if version_parts.size >= 2
        entry['patch_version'] = version_parts[2] if version_parts.size == 3

        versions << entry
      end

      versions
    end

    #    context "with no versions key" do
    #      it "logs error message" do
    #        desc='{}'
    #        options[:distro] = JSON.parse(desc)
    #        options[:version] = "12.4.5"
    #        allow(FileUtils).to receive(:remove_dir)
    #
    #        expect(logger).to receive(:error)
    #        creator = Comfy::Creator.new(options,logger)
    #        expect{creator.send(:choose_version)}.to raise_error(SystemExit)
    #      end
    #    end
    context 'with empty versions array (user selects newest)' do
      it 'logs error message' do
        desc = '{"versions": []}'
        options[:distro] = JSON.parse(desc)
        options[:version] = 'newest'.to_sym
        allow(FileUtils).to receive(:remove_dir)
        creator = Comfy::Creator.new(options, logger)

        expect(logger).to receive(:error)
        expect {subject}.to raise_error(SystemExit)
      end
    end
    context 'with empty versions array (user selects some version)' do
      it 'logs error message' do
        desc = '{"versions": []}'
        options[:distro] = JSON.parse(desc)
        options[:version] = '123.4.5'
        allow(FileUtils).to receive(:remove_dir)
        creator.instance_variable_set('@options', options)

        expect(logger).to receive(:error)
        expect {subject}.to raise_error(SystemExit)
      end
    end
    context 'single version available, user selects nonexistent version' do
      it 'logs error message' do
        options[:distro] = { 'versions' => create_versions(['12.7.11']) }
        options[:version] = '15.4.5'
        allow(FileUtils).to receive(:remove_dir)
        creator.instance_variable_set('@options', options)

        expect(logger).to receive(:error)
        expect {subject}.to raise_error(SystemExit)
      end
    end
    context 'single version available, user selects newest' do
      it 'selects the newest version' do
        options[:distro] = { 'versions' => create_versions(['12.7.11']) }
        options[:version] = 'newest'.to_sym
        allow(FileUtils).to receive(:remove_dir)
        creator.instance_variable_set('@options', options)

        is_expected.to eq(create_versions(['12.7.11']).first)
      end
    end
    context 'single version available, user selects it' do
      it 'selects the correct version' do
        options[:distro] = { 'versions' => create_versions(['14.51']) }
        options[:version] = '14.51'
        allow(FileUtils).to receive(:remove_dir)
        creator.instance_variable_set('@options', options)

        is_expected.to eq(create_versions(['14.51']).first)
      end
    end
    context 'version 14.04 available, user selects 14.04.05' do
      it 'logs error message' do
        options[:distro] = { 'versions' => create_versions(['14.04']) }
        options[:version] = '14.04.05'
        allow(FileUtils).to receive(:remove_dir)
        creator.instance_variable_set('@options', options)

        expect(logger).to receive(:error)
        expect {subject}.to raise_error(SystemExit)
      end
    end
    context 'version 14.05 available, user selects 14' do
      it 'selects version 14.05' do
        options[:distro] = { 'versions' => create_versions(['14.05']) }
        options[:version] = '14'
        allow(FileUtils).to receive(:remove_dir)
        creator.instance_variable_set('@options', options)

        is_expected.to eq(create_versions(['14.05']).first)
      end
    end
    context 'version 14.05 available, user selects 14.5' do
      it 'selects version 14.05' do
        options[:distro] = { 'versions' => create_versions(['14.05']) }
        options[:version] = '14.5'
        allow(FileUtils).to receive(:remove_dir)
        creator.instance_variable_set('@options', options)

        is_expected.to eq(create_versions(['14.05']).first)
      end
    end
    context 'version 14.05 available, user selects 14.6' do
      it 'logs error message' do
        options[:distro] = { 'versions' => create_versions(['14.05']) }
        options[:version] = '14.6'
        allow(FileUtils).to receive(:remove_dir)
        creator.instance_variable_set('@options', options)

        expect(logger).to receive(:error)
        expect {subject}.to raise_error(SystemExit)
      end
    end
    context 'version 14.05 available, user selects 5.' do
      it 'logs error message' do
        options[:distro] = { 'versions' => create_versions(['14.05']) }
        options[:version] = '5.'
        allow(FileUtils).to receive(:remove_dir)
        creator.instance_variable_set('@options', options)

        expect(logger).to receive(:error)
        expect {subject}.to raise_error(SystemExit)
      end
    end
    context 'version 14.05 available, user selects 14....' do
      it 'selects version 14.05' do
        options[:distro] = { 'versions' => create_versions(['14.05']) }
        options[:version] = '14....'
        allow(FileUtils).to receive(:remove_dir)
        creator.instance_variable_set('@options', options)

        is_expected.to eq(create_versions(['14.05']).first)
      end
    end
    context 'version 14.05 available, user selects 14.5....' do
      it 'selects 14.05' do
        options[:distro] = { 'versions' => create_versions(['14.05']) }

        options[:version] = '14.5....'
        allow(FileUtils).to receive(:remove_dir)
        creator.instance_variable_set('@options', options)

        is_expected.to eq(create_versions(['14.05']).first)
      end
    end
    context 'multiple versions available, user selects nonexistent version' do
      let(:versions) { { 'versions' => create_versions(['13.05', '7.1', '12.05.4', '14', '14.5', '14.5.02', '12.3.15', '11', '11.4', '11.01']) } }

      it 'logs error message' do
        options[:distro] = versions
        options[:version] = '15'
        allow(FileUtils).to receive(:remove_dir)
        creator.instance_variable_set('@options', options)

        expect(logger).to receive(:error)
        expect {subject}.to raise_error(SystemExit)
      end

      it 'logs error message' do
        options[:distro] = versions
        options[:version] = '11.3'
        allow(FileUtils).to receive(:remove_dir)
        creator.instance_variable_set('@options', options)

        expect(logger).to receive(:error)
        expect {subject}.to raise_error(SystemExit)
      end
      it 'logs error message' do
        options[:distro] = versions
        options[:version] = '14.5.10'
        allow(FileUtils).to receive(:remove_dir)
        creator.instance_variable_set('@options', options)

        expect(logger).to receive(:error)
        expect {subject}.to raise_error(SystemExit)
      end
    end
    context 'multiple versions available, user selects newest' do
      it 'selects the newest version' do
        options[:distro] = { 'versions' => create_versions(['14.05', '7.1', '12.05.4', '08.02.3', '14.4.5', '14.3.15']) }
        options[:version] = :newest
        allow(FileUtils).to receive(:remove_dir)
        creator.instance_variable_set('@options', options)

        res = creator.send(:choose_version)
        expect(res).to eq(create_versions(['14.05']).first)
      end
    end
    context 'multiple versions available, user selects correct version' do
      let(:versions) { { 'versions' => create_versions(['13.05', '7.1', '12.05.4', '14', '14.5', '14.5.2', '14.05.07', '14.5.03', '11.4', '11.01']) } }

      it 'selects the correct version' do
        options[:distro] = versions
        options[:version] = '14'
        allow(FileUtils).to receive(:remove_dir)
        creator.instance_variable_set('@options', options)

        is_expected.to eq(create_versions(['14']).first)
      end

      it 'selects the correct version' do
        options[:distro] = versions
        options[:version] = '14.5'
        allow(FileUtils).to receive(:remove_dir)
        creator.instance_variable_set('@options', options)

        is_expected.to eq(create_versions(['14.05']).first)
      end

      it 'selects the correct version' do
        options[:distro] = versions
        options[:version] = '14.5.7'
        allow(FileUtils).to receive(:remove_dir)
        creator.instance_variable_set('@options', options)

        is_expected.to eq(create_versions(['14.05.07']).first)
      end
    end
    context 'multiple versions available, user selects something but only more specifc version is available' do
      let(:versions) { { 'versions' => create_versions(['12', '7.1', '12.05.4', '14', '14.5', '14.5.2', '14.05.07', '14.5.03', '11.04', '11.1']) } }

      it 'selects the correct version' do
        options[:distro] = versions
        options[:version] = '11'
        allow(FileUtils).to receive(:remove_dir)
        creator.instance_variable_set('@options', options)

        is_expected.to eq(create_versions(['11.04']).first)
      end

      it 'selects the correct version' do
        options[:distro] = versions
        options[:version] = '12.5'
        allow(FileUtils).to receive(:remove_dir)
        creator.instance_variable_set('@options', options)

        is_expected.to eq(create_versions(['12.05.4']).first)
      end
    end
  end

  describe '.prepare_data' do
    it 'fills in instance variable options' do
      correct_options = { distro: {}, provisioners: {}, password: 'pass_word' }
      correct_options[:distro][:version] = '12345'
      correct_options[:provisioners][:scripts] = %w(1 2 3)
      correct_options[:provisioners][:files] = %w(1 2 3)

      creator = Comfy::Creator.new({}, logger)
      allow(File).to receive(:read).and_return('description of distro')
      allow(JSON).to receive(:parse).and_return(correct_options[:distro])

      allow(creator).to receive(:choose_version).and_return(correct_options[:distro][:version])
      allow(creator).to receive(:password).and_return(correct_options[:password])
      allow(creator).to receive(:get_group).and_return(correct_options[:provisioners][:files])
      expect(JSON).to receive(:parse).with('description of distro')

      creator.send(:prepare_data, 'distribution', '/tmp/')
      expect(creator.instance_variable_get('@options')).to eq(correct_options)
    end
  end
end
