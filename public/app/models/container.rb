class Container < Record
  def display_string
    bits = []
    bits << I18n.t("enumerations.container_type.#{@json['type']}", default: @json['type'].capitalize) if @json['type']
    bits << @json['indicator']

    bits.join(' ')
  end
end
