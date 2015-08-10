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

#  describe '#check_files' do
#  end

  describe '#check_options_restrictions' do
    context 'with disk size < 0' do
      before :example do
        options.size = -100
      end

      it 'Fails with ArgumentError' do
        expect {Comfy::Opts.check_options_restrictions(options)}.to raise_error(ArgumentError)
      end
    end

    context 'with disk size = 0' do
      before :example do
        options.size = 0
      end

      it 'Fails with ArgumentError' do
        expect {Comfy::Opts.check_options_restrictions(options)}.to raise_error(ArgumentError)
      end
    end
  end

  describe '#check_settings_restrictions' do
    context 'with missing output directory' do
      before :example do
        Settings['output_dir'] = ''
      end

      it 'Fails with ArgumentError' do
        expect {Comfy::Opts.check_settings_restrictions(options)}.to raise_error(ArgumentError)
      end
    end

    context 'with missing packer cache directory' do
      before :example do
        Settings['packer_cache_dir'] = ''
      end

      it 'Fails with ArgumentError' do
        expect {Comfy::Opts.check_settings_restrictions(options)}.to raise_error(ArgumentError)
      end
    end

  end

end
