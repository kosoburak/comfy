require_relative '../spec_helper'

describe Comfy::Opts do
  
  let(:options) {OpenStruct.new}

  describe '#parse' do

  end

#  describe '#list_distributions' do
#  end

#  describe '#copy_templates' do
#  end

#  describe '#clean_cache' do
#  end

  describe '#set_defaults' do

    context 'with empty options' do
      it 'sets the default values' do
        Comfy::Opts.set_defaults(options)
        expect(options.formats). to eq([Comfy::Opts::FORMAT_DEFAULT])
        expect(options.size). to eq(Comfy::Opts::SIZE_DEFAULT)
        expect(options.debug). to eq(Comfy::Opts::DEBUG_DEFAULT)
        expect(options.template_dir). to eq(Comfy::Opts::DIR)
        expect(options.version). to eq(:newest)
      end
    end

    context 'with format set' do
      before :example do
        options.formats = [:raw]
      end
      it 'takes format from options' do
        Comfy::Opts.set_defaults(options)
        expect(options.formats). to eq([:raw])
        expect(options.size). to eq(Comfy::Opts::SIZE_DEFAULT)
        expect(options.debug). to eq(Comfy::Opts::DEBUG_DEFAULT)
        expect(options.template_dir). to eq(Comfy::Opts::DIR)
        expect(options.version). to eq(:newest)
      end
    end

    context 'with size set' do
      before :example do
        options.size = 300
      end
      it 'takes size from options' do
        Comfy::Opts.set_defaults(options)
         expect(options.formats). to eq([Comfy::Opts::FORMAT_DEFAULT])
         expect(options.size). to eq(300)
         expect(options.debug). to eq(Comfy::Opts::DEBUG_DEFAULT)
         expect(options.template_dir). to eq(Comfy::Opts::DIR)
         expect(options.version). to eq(:newest)
      end
    end

    context 'with debug mode on' do
      before :example do
        options.debug = true
      end
      it 'debug mode is enabled' do
        Comfy::Opts.set_defaults(options)
        expect(options.formats). to eq([Comfy::Opts::FORMAT_DEFAULT])
        expect(options.size). to eq(Comfy::Opts::SIZE_DEFAULT)
        expect(options.debug). to be true
        expect(options.template_dir). to eq(Comfy::Opts::DIR)
        expect(options.version). to eq(:newest)
      end
    end

#    context 'with template dir set' do
#    end

#    context 'with version set' do
#    end

  end

  describe '#check_files' do

    context 'with incorrect (missing) packer file' do
      before :example do
        options.distribution = 'debian'
        allow(File).to receive(:exist?).and_return(false)
      end
      it 'fails with ArgumentError' do
        expect {Comfy::Opts.check_files(options)}.to raise_error(ArgumentError)
      end
    end

    context 'with correct packer cfg file' do
      before :example do
        options.distribution = 'debian'
        allow(File).to receive(:exist?).and_return(true)
      end
      it 'will pass without failure' do
        Comfy::Opts.check_files(options)
      end
    end
  end


  describe '#check_distro_dir' do

    context 'with incorrect (missing) distro_dir' do
      before :example do 
        allow(File).to receive(:exist?).and_return(false)
      end
      let(:distro_dir) {"#{Comfy::Opts::DIR}/win98"}  
      let(:distro) {'win98'}
      it 'fails with ArgumentError' do
        expect {Comfy::Opts.check_distro_dir(distro_dir, distro)}.to raise_error(ArgumentError)
      end
    end

    context 'with correct distro_dir' do
      before :example do 
        allow(File).to receive(:exist?).and_return(true)
      end
      let(:distro_dir) {"#{Comfy::Opts::DIR}/debian"}
      let(:distro) {'debian'}
      it 'fill pass without failure' do
        Comfy::Opts.check_distro_dir(distro_dir, distro)
      end
    end
  end

  describe '#check_distro_cfg' do

    context 'with incorrect (missing) cfg.erb file' do
      before :example do
        allow(File).to receive(:exist?).and_return(false)
      end
      let(:distro_cfg) {"#{Comfy::Opts::DIR}/debian/rimmer.cfg.erb"}
      let(:distro) {'debian'}
      it 'fails with ArgumentError' do
         expect {Comfy::Opts.check_distro_cfg(distro_cfg, distro)}.to raise_error(ArgumentError)
      end
    end

    context 'with correct distro_cfg' do
      before :example do
        allow(File).to receive(:exist?).and_return(true)
      end
      let(:distro_cfg) {"#{Comfy::Opts::DIR}/debian/debian.cfg.erb"}
      let(:distro) {'debian'}
      it 'will pass without failure' do
        Comfy::Opts.check_distro_cfg(distro_cfg, distro)
      end
    end
  end

  describe '#check_distro_description' do

    context 'with incorrect (missing) description file' do
      before :example do
        allow(File).to receive(:exist?).and_return(false)
      end
      let(:distro_description) {"#{Comfy::Opts::DIR}/debian/lister.description"}
      let(:distro) {'debian'}
      it 'fails with ArgumentError' do
        expect {Comfy::Opts.check_distro_description(distro_description, distro)}.to raise_error(ArgumentError)
      end
    end

    context 'with corrcet distro_description' do
      before :example do
        allow(File).to receive(:exist?).and_return(true)
      end
      let(:distro_description) {"#{Comfy::Opts::DIR}/debian/debian.description"}
      let(:distro) {'debian'}
      it 'will pass without failure' do
        Comfy::Opts.check_distro_description(distro_description, distro)
      end
    end
  end



  describe '#check_options_restrictions' do

    context 'with disk size < 0' do
      before :example do
        options.size = -100
      end
      it 'fails with ArgumentError' do
        expect {Comfy::Opts.check_options_restrictions(options)}.to raise_error(ArgumentError)
      end
    end

    context 'with disk size = 0' do
      before :example do
        options.size = 0
      end
      it 'fails with ArgumentError' do
        expect {Comfy::Opts.check_options_restrictions(options)}.to raise_error(ArgumentError)
      end
    end
  end

  describe '#check_settings_restrictions' do

    context 'with missing output directory' do
      before :example do
        Settings['output_dir'] = ''
      end
      it 'fails with ArgumentError' do
        expect {Comfy::Opts.check_settings_restrictions(options)}.to raise_error(ArgumentError)
      end
    end

    context 'with missing packer cache directory' do
      before :example do
        Settings['packer_cache_dir'] = ''
      end
      it 'fails with ArgumentError' do
        expect {Comfy::Opts.check_settings_restrictions(options)}.to raise_error(ArgumentError)
      end
    end

  end

end
