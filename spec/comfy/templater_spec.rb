require_relative '../spec_helper'
describe Comfy::Templater do
  let(:logger) { Logger.new(STDERR) }
  let(:mocks_source_path) { File.expand_path(File.dirname(__FILE__)) + '/mocks/' }

  describe '.prepare_files' do
    # check for existence of files and if they contain whatever populate_template returns
    # whether templates are filled correctly is checked in prepare_template
    it 'outputs correct files' do
      returned = 'something that populate_template returns'
      data = { distribution: 'abc', template_dir: 'asd', server_dir: '/tmp' }
      templater = Comfy::Templater.new(data, logger)
      allow(templater).to receive(:populate_template).and_return(returned)
      templater.send(:prepare_files)

      path1 = "#{data[:server_dir]}/#{data[:distribution]}.packer"
      path2 = "#{data[:server_dir]}/#{data[:distribution]}.cfg"

      expect(File.exist?(path1)).to eq(true)
      expect(File.exist?(path2)).to eq(true)

      expect(File.open(path1).read).to eq(returned)
      expect(File.open(path2).read).to eq(returned)
    end
  end

  describe '.prepare_template' do
    it 'prepares the template' do
      # create data hash
      # "types" of specific values inferred from opts parser and usage, not necessarily correct

      data = {}
      # defined in bin/comfy
      data[:size] = 5000
      data[:builders] = [:qemu, :virtualbox] # real values needed to fill specific template parts
      data[:distribution] = 'options.distribution'
      data[:headless] = false
      data[:template_dir] = 'options.template_dir'
      data[:version] = '7.8.0'
      data[:output_dir] = "Settings['output_dir']"

      # defined in lib/comfy/creator
      data[:server_dir] = 'server_dir'
      data[:distro] = JSON.parse(File.read(mocks_source_path + 'templater_spec_cfg_description'))
      data[:distro][:version] = data[:distro]['versions'][0]
      data[:provisioners] = {}
      data[:provisioners][:scripts] = ['script1', 'script2', 'script/with/slash', '', 'script with spaces']
      data[:provisioners][:files] = ['file1', '2file_starting_with_number', 'file with spaces', 'file/slash']
      data[:password] = 'some password'

      # fill templates using populate_template method
      templater = Comfy::Templater.new(data, logger)
      filled_packer = templater.send(:populate_template, mocks_source_path + 'templater_spec_packer.erb')
      filled_cfg = templater.send(:populate_template, mocks_source_path + 'templater_spec_cfg.erb')

      # compare created templates with respective correctly filled versions
      correct_packer = File.read(mocks_source_path + 'templater_spec_packer_correct')
      correct_cfg = File.read(mocks_source_path + 'templater_spec_cfg_correct')

      expect(filled_packer).to eq(correct_packer)
      expect(filled_cfg).to eq(correct_cfg)
    end
  end
end
