class Username
  def self.value(s)
    s = s.downcase.strip

    raise InvalidUsernameException if s !~ /\A[a-zA-Z0-9\-_. @]+\z/ || s =~ /  +/

    s
  end
end
