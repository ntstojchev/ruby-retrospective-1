require 'enumerator'

class Array
  def to_hash
    inject({}) do |hash, el|
      hash[el[0]] = el[1]
      hash
    end
  end

  def index_by
    inject({}) do |hash, el|
      hash[yield el] = el
      hash
    end
  end

  def subarray_count(value)
    count = 0
    each_cons(value.size) { |sub_arr| count += 1 if sub_arr == value }
    count
  end

  def occurences_count
    inject(Hash.new 0) do |hash, el|
      hash[el] += 1
      hash
    end
  end
end