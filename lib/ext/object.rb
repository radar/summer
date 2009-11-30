class Object
  def call(method, *args)
    try(method, *args) if respond_to?(method)
  end
end