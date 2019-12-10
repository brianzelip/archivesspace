# Modified to return descriptions in OAI_DC format so our responses validate.
module OAI::Provider::Response
  class ListSets < Base
    def to_xml
      raise OAI::SetException unless provider.model.sets

      response do |r|
        r.ListSets do
          provider.model.sets.each do |set|
            r.set do
              r.setSpec set.spec
              r.setName set.name
              r << set.description if set.respond_to?(:description) && set.description
            end
          end
        end
      end
    end
  end
end
