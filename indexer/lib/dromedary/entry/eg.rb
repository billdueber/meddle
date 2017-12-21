require 'dromedary/entry/citation'

module Dromedary
  class Entry

    # EG == "Example Given" a set of related citations. Entries often
    # have more than one EG section, one for each sub-definition.
    class EG

      # @return [Array<Citation>] The citations for this set of examples
      attr_reader :citations

      # @return [String, nil] The sub-definition this set of citations refers to
      attr_reader :subdef_entry

      # @param [Nokogiri::XML::Element] nokonode The nokogiri node for this element
      def initialize(nokonode)
        return if nokonode == :empty
        @citations    = nokonode.xpath('CIT').map {|x| Citation.new(x)}
        @subdef_entry = nokonode.attribute('N') && nokonode.attribute('N').value.downcase
      end

    end
  end
end