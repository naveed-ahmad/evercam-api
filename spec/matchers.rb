RSpec::Matchers.define :have_css do |css|
  match do |actual|
    false == actual.css(css).empty?
  end
end

RSpec::Matchers.define :have_fragment do |fragments|
  match do |actual|
    uri = URI.parse(actual)
    ary = URI.decode_www_form(uri.fragment || '')

    act = Hash[*ary.flatten]
    fragments.all? { |k,v| act[k.to_s] == v.to_s }
  end
end

RSpec::Matchers.define :have_parameter do |entries|
  match do |actual|
    uri        = URI.parse(actual)
    parameters = CGI.parse(uri.query).inject({}) do |list, entry|
      list[entry[0].to_s] = entry[1][0]
      list
    end
    entries.all? { |k,v| parameters[k.to_s] == v.to_s }
  end
end

RSpec::Matchers.define :have_keys do |*keys|
  match do |actual|
    keys.all? { |k| actual.keys.include?(k) }
  end
end

RSpec::Matchers.define :not_have_keys do |*keys|
  match do |actual|
    keys.inject(0) {|total, key| total += 1 if actual.include?(key); total} == 0
  end
end

RSpec::Matchers.define :be_around_now do
  match do |actual|
    1 >= (actual - Time.now)
  end
end

RSpec::Matchers.define :be_dataset do |expected|
  match do |actual|
    expected.all? do |m|
      actual.include?(m)
    end &&
    actual.all? do |m|
      expected.include?(m)
    end
  end
end

