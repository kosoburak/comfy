require_relative '../spec_helper'

describe Comfy::Opts do
  
  let(:options) {OpenStruct.new}

#  describe '#parse' do
#  end

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

#    context 'with format set' do
#    end

#    context 'with size set' do
#    end

#    context 'with debug mode on' do
#    end

#    context 'with template dir set' do
#    end

#    context 'with version set' do
#    end

  end

#  describe '#check_files' do
#  end

#  describe '#check_options_restrictions' do
#  end

#  describe '#check_settings_restrictions' do
#  end

end
