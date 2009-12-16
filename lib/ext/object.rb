class Object
  def really_try(method, *args)
    try(method, *args) if respond_to?(method)
  end
end