module Report
  module Component

    # A component to include metainfo like image_post_path.
    class Meta
      def initialize(field_hash={})
        @field_hash = field_hash
      end
  
      def as_json(options=nil)
        {:type => 'meta'}.merge(@field_hash).as_json(options)
      end
      
      def to_pdf(pdf); end
      
      def method_missing(meth, *args)
        meth_name = meth.to_s
        if meth_name =~ /(.*)=$/
          @field_hash[meth_name.chop] = args.first
        else
          @field_hash[meth_name]
        end
      end  
    end

  end # module Component
end # module Report
