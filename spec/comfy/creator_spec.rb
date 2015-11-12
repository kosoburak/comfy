require_relative '../spec_helper'

describe Comfy::Creator do
  let(:options) { { distro: {'name' => 'any_distro'}, server_dir: 'any_dir', groups: ["a","b","c"] } }
  let(:creator) { Comfy::Creator.new(options) }

  describe ".replace_needles" do
    it "returns the correct string" do
      allow(creator).to receive(:version_string).and_return("123456")
      format_str = "acbd!@$v-$v$-n$n$x&x$g"
      expect(creator.send(:replace_needles,format_str)).to eq "acbd!@123456-123456$-nany_distro$x&xa,b,c"
    end

    it "returns the correct string" do
      allow(creator).to receive(:version_string).and_return("123456")
      format_str = "$$$$$/__$$x$$n-*$"
      expect(creator.send(:replace_needles,format_str)).to eq "$$$$$/__$$x$any_distro-*$"
    end
  end

  describe '.password' do
    it 'returns different 100 chars long passwords' do
      pwds = []
      30.times do
        pwd = creator.send(:password)
        expect(pwd.length).to eq(100)
        pwds << pwd
      end
      expect(pwds.length).to eq(pwds.uniq.length)
    end
  end

  describe '.choose_version' do
    # it's okay to assume the JSON file is well-formed, otherwise
    # the whole thing would crash while parsing it, however
    # no assumptions can be made about the contents of the file (saved in desc)

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

    context 'with empty versions array (user selects newest)' do
      it 'logs error message' do
        desc = '{"versions": []}'
        options[:distro] = JSON.parse(desc)
        options[:version] = 'newest'.to_sym
        allow(FileUtils).to receive(:remove_dir)
        creator.data = options

        expect {subject}.to raise_exception
      end
    end
    context 'with empty versions array (user selects some version)' do
      it 'logs error message' do
        desc = '{"versions": []}'
        options[:distro] = JSON.parse(desc)
        options[:version] = '123.4.5'
        allow(FileUtils).to receive(:remove_dir)
        creator.data = options

        expect {subject}.to raise_exception
      end
    end
    context 'single version available, user selects nonexistent version' do
      it 'logs error message' do
        options[:distro] = { 'versions' => create_versions(['12.7.11']) }
        options[:version] = '15.4.5'
        allow(FileUtils).to receive(:remove_dir)
        creator.data = options

        expect {subject}.to raise_exception
      end
    end
    context 'single version available, user selects newest' do
      it 'selects the newest version' do
        options[:distro] = { 'versions' => create_versions(['12.7.11']) }
        options[:version] = 'newest'.to_sym
        allow(FileUtils).to receive(:remove_dir)
        creator.data = options

        is_expected.to eq(create_versions(['12.7.11']).first)
      end
    end
    context 'single version available, user selects it' do
      it 'selects the correct version' do
        options[:distro] = { 'versions' => create_versions(['14.51']) }
        options[:version] = '14.51'
        allow(FileUtils).to receive(:remove_dir)
        creator.data = options

        is_expected.to eq(create_versions(['14.51']).first)
      end
    end
    context 'version 14.04 available, user selects 14.04.05' do
      it 'logs error message' do
        options[:distro] = { 'versions' => create_versions(['14.04']) }
        options[:version] = '14.04.05'
        allow(FileUtils).to receive(:remove_dir)
        creator.data = options

        expect {subject}.to raise_exception
      end
    end
    context 'version 14.05 available, user selects 14' do
      it 'selects version 14.05' do
        options[:distro] = { 'versions' => create_versions(['14.05']) }
        options[:version] = '14'
        allow(FileUtils).to receive(:remove_dir)
        creator.data = options

        is_expected.to eq(create_versions(['14.05']).first)
      end
    end
    context 'version 14.05 available, user selects 14.5' do
      it 'selects version 14.05' do
        options[:distro] = { 'versions' => create_versions(['14.05']) }
        options[:version] = '14.5'
        allow(FileUtils).to receive(:remove_dir)
        creator.data = options

        is_expected.to eq(create_versions(['14.05']).first)
      end
    end
    context 'version 14.05 available, user selects 14.6' do
      it 'logs error message' do
        options[:distro] = { 'versions' => create_versions(['14.05']) }
        options[:version] = '14.6'
        allow(FileUtils).to receive(:remove_dir)
        creator.data = options

        expect {subject}.to raise_exception
      end
    end
    context 'version 14.05 available, user selects 5.' do
      it 'logs error message' do
        options[:distro] = { 'versions' => create_versions(['14.05']) }
        options[:version] = '5.'
        allow(FileUtils).to receive(:remove_dir)
        creator.data = options

        expect {subject}.to raise_exception
      end
    end
    context 'version 14.05 available, user selects 14....' do
      it 'selects version 14.05' do
        options[:distro] = { 'versions' => create_versions(['14.05']) }
        options[:version] = '14....'
        allow(FileUtils).to receive(:remove_dir)
        creator.data = options

        is_expected.to eq(create_versions(['14.05']).first)
      end
    end
    context 'version 14.05 available, user selects 14.5....' do
      it 'selects 14.05' do
        options[:distro] = { 'versions' => create_versions(['14.05']) }

        options[:version] = '14.5....'
        allow(FileUtils).to receive(:remove_dir)
        creator.data = options

        expect(subject).to eq(create_versions(['14.05']).first)
      end
    end
    context 'multiple versions available, user selects nonexistent version' do
      let(:versions) { { 'versions' => create_versions(['13.05', '7.1', '12.05.4', '14', '14.5', '14.5.02', '12.3.15', '11', '11.4', '11.01']) } }

      it 'logs error message' do
        options[:distro] = versions
        options[:version] = '15'
        allow(FileUtils).to receive(:remove_dir)
        creator.data = options

        expect {subject}.to raise_exception
      end

      it 'logs error message' do
        options[:distro] = versions
        options[:version] = '11.3'
        allow(FileUtils).to receive(:remove_dir)
        creator.data = options

        expect {subject}.to raise_exception
      end
      it 'logs error message' do
        options[:distro] = versions
        options[:version] = '14.5.10'
        allow(FileUtils).to receive(:remove_dir)
        creator.data = options

        expect {subject}.to raise_exception
      end
    end
    context 'multiple versions available, user selects newest' do
      it 'selects the newest version' do
        options[:distro] = { 'versions' => create_versions(['14.05', '7.1', '12.05.4', '08.02.3', '14.4.5', '14.3.15']) }
        options[:version] = :newest
        allow(FileUtils).to receive(:remove_dir)
        creator.data = options

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
        creator.data = options

        is_expected.to eq(create_versions(['14.05.07']).first)
      end

      it 'selects the correct version' do
        options[:distro] = versions
        options[:version] = '14.5'
        allow(FileUtils).to receive(:remove_dir)
        creator.data = options

        is_expected.to eq(create_versions(['14.05.07']).first)
      end

      it 'selects the correct version' do
        options[:distro] = versions
        options[:version] = '14.5.7'
        allow(FileUtils).to receive(:remove_dir)
        creator.data = options

        is_expected.to eq(create_versions(['14.05.07']).first)
      end
    end
    context 'multiple versions available, user selects something but only more specifc version is available' do
      let(:versions) { { 'versions' => create_versions(['12', '7.1', '12.05.4', '14', '14.5', '14.5.2', '14.05.07', '14.5.03', '11.04', '11.1']) } }

      it 'selects the correct version' do
        options[:distro] = versions
        options[:version] = '11'
        allow(FileUtils).to receive(:remove_dir)
        creator.data = options

        is_expected.to eq(create_versions(['11.04']).first)
      end

      it 'selects the correct version' do
        options[:distro] = versions
        options[:version] = '12.5'
        allow(FileUtils).to receive(:remove_dir)
        creator.data = options

        is_expected.to eq(create_versions(['12.05.4']).first)
      end
    end
  end
end
