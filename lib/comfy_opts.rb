require 'optparse'
require 'optparse/time'
require 'ostruct'
require 'pp'

# Just for compairing input distributions to create
class Array
  def contains_all? other
    other = other.dup
    each{|e| if i = other.index(e) then other.delete_at(i) end} 
    other.empty?
  end
end


# Class for parsing command line arguments
class ComfyOpts
  FORMAT_DEFAULT = 'qcow2'
  SIZE_DEFAULT = 5000
  DISTROS_DEFAULT = ["centos", "debian", "sl", "ubuntu"]

  DIR = "#{File.dirname(__FILE__)}/"

  CENTOS_TEMPLATE = DIR + 'templates/centos/centos.erb'
  CENTOS_INSTAL = DIR + 'templates/centos/kickstart.cfg'
  DEBIAN_TEMPLATE = DIR + 'templates/debian/debian.erb'
  DEBIAN_INSTAL = DIR + 'templates/debian/preseed.cfg'
  SL_TEMPLATE = DIR + 'templates/sl/sl.erb'
  SL_INSTAL = DIR + 'templates/sl/kickstart.cfg'
  UBUNTU_TEMPLATE = DIR + 'templates/ubuntu/ubuntu.erb'
  UBUNTU_INSTAL = DIR + 'templates/ubuntu/preseed.cfg'

# Return a structure with options

  def self.parse(args)
    options = OpenStruct.new

    opt_parser = OptionParser.new do |opts|
      opts.banner = 'Usage of COMFY tool: comfy.rb [options]'
      opts.separator ''

      opts.on('--distros centos,debian,sl,ubuntu', Array,
              'List of distributions to create:',
              'centos',
              'debian',
              'sl',
              'ubuntu',
              'By default, it is all of them',
              ' ') do |list|
        options.distros = list
      end

      formats = [:raw, :qcow2]       
      opts.on('--format=FORMAT', formats,
              'Select the output format of the virtual machine image.',
              'Choose from ["raw", "qcow2"].',
              'By default, it is "qcow2".',
              ' ') do |f|
        options.format = f
      end

      opts.on('--size [NUMBER]', Integer,
              'The size in MB of the hard disk to create for the VM',
              'By default, it is 5000 (5GB)',
              ' ') do |s|
        options.size = s
      end

      opts.on_tail('-h', '--help', 'Shows this message') do
        puts opts
        exit
      end

      opts.on_tail('-v', '--version', 'Shows version') do
        puts ::Version.join('.')
        exit
      end
    end
    
    begin
      opt_parser.parse!(args)
    rescue OptionParser::ParseError => e
      puts e
      exit 1
    end

    set_defaults(options)
    check_files(options)
    check_distros(options)

    options
  end  # parse()

  # Set default values for not specified options
  def self.set_defaults(options)
    options.format = FORMAT_DEFAULT unless options.format
    options.size = SIZE_DEFAULT unless options.size
    options.distros = DISTROS_DEFAULT unless options.distros 
  end

  # Make sure we have templates
  def self.check_files(options)

    missing_files = ''

    #make sure date range make sense
    if options.distros.include? 'centos'
      if !File.file?(CENTOS_TEMPLATE) || !File.file?(CENTOS_INSTAL)
        missing_files << "Missing template or kickstart file for CentOS.\n"
      end
    end
    if options.distros.include? 'debian'
      if !File.file?(DEBIAN_TEMPLATE) || !File.file?(DEBIAN_INSTAL)
        missing_files << "Missing template of pressed file for Debian.\n"
      end
    end
    if options.distros.include? 'sl'
      if !File.file?(SL_TEMPLATE) || !File.file?(SL_INSTAL)
        missing_files << "Missing template or kickstart file for SL.\n"
      end
    end
    if options.distros.include? 'ubuntu'
      if !File.file?(UBUNTU_TEMPLATE) || !File.file?(UBUNTU_INSTAL)
        missing_files << "Missing template or preseed file for Ubuntu.\n"
      end
    end

    fail IOError, missing_files unless missing_files.empty? 
  end  #check_files

  def self.check_distros(options)
    puts "[WARNING]:Used some unknown distros, but moving on.\n\n" unless DISTROS_DEFAULT.contains_all? options.distros
  end

end

options = ComfyOpts.parse(ARGV)
pp options
pp ARGV


__END__

