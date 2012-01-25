module Report
  module Component

    # A component to include metainfo like image_post_path.
    class Meta
      def initialize(field_hash={})
        @field_hash = field_hash
      end
  
      def to_json(options={})
        {:type => 'meta'}.merge(@field_hash).to_json(options)
      end
      
      def to_pdf(pdf); end
      
      def method_missing(meth, *args)
        meth_name = meth.to_s
        if meth_name =~ /(.*)=$/
          @field_hash[meth_name.chop] = *args
        else
          @field_hash[meth_name]
        end
      end  
    end

  end # module Component
end # module Report