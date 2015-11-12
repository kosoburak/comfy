require 'yell'

# Monkeypatch for Yell
class Yell::Logger
  def <<(x)
    info x.strip
  end
end
