class QuerySet

  def initialize(model_class)
    self.model_class = model_class
  end

  def filter(**params)

  end

  def exists?

  end

  def count

  end

  def order(**params)

  end

  def lock(type="pessimistic")

  end

end