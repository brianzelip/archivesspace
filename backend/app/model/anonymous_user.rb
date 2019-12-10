class AnonymousUser
  def anonymous?
    true
  end

  def username
    nil
  end

  def can?(_permission, _opts = {})
    false
  end
end
