
module Report
  module OFC
    Max_X_Labels = 30

    # Base class for Open Flash Charts 2 charts.
    class Base
      attr_accessor :chart_image_key, :key

      def initialize(title, labels, elements, y_max, *opts)
        set_defaults(title, labels, y_max, opts)
        @chart[:elements] = elements
        set_element_types
      end

      def no_data?; false; end

      def set_defaults(title, labels, y_max, opts=[])
        label_size = 12
        @chart ||= {}
        @chart[:type] = 'chart'
        @chart[:bg_colour] = "#ffffff"
        @chart[:title] = {:text => title} if title
        @chart[:x_axis] = {:labels => {:labels => labels,
                                       :size => label_size,
                                       :colour => "#888888"}}

        @chart[:x_axis][:labels][:rotate] = 'diagonal' \
          if opts.include?(:diagonal_labels)
        @chart[:x_axis][:labels][:rotate] = 'vertical' \
          if opts.include?(:vertical_labels)

        @chart[:y_axis] = {:max => y_max} if y_max
        steps = ((y_max || 0) / 10)
        @chart[:y_axis][:steps] = steps if steps > 0
        set_y_legend('Count')
      end

      # adjusts label step size to be reasonable
      def limit_labels
        labels = @chart[:x_axis][:labels][:labels]
        return if labels.size < Max_X_Labels

        factors = (labels.size - 1).factorize
        step_size = factors.pop # the biggest factor
        factors.reverse!
        while ((labels.size / step_size) > Max_X_Labels)
          break if factors.empty?
          step_size *= factors.pop
        end
        new_labels = []
        labels.each_with_index do |l,i|
          new_l = (i % step_size == 0 ? l : '')
          new_labels << new_l
        end
        @chart[:x_axis][:labels][:labels] = new_labels
      end

      def image_post_url; @chart[:image_post_url]; end
      def image_post_url=(url); @chart[:image_post_url] = url; end

      def as_json(options=nil)
        if no_data?
          Report::Component::Text.new(:p, '--- No chart data! ---').as_json(options)
        else
          @chart.merge(:key => self.key).as_json(options)
        end
      end

      def to_pdf(pdf)
        # N.B. The chart_image_key has to have scoping info
        img = ChartImage.find(
                :last,
                :conditions => {:data => self.chart_image_key})
        if img
          pdf.pad_bottom(20) do
            i = Prawn::Images::PNG.new(File.open(img.file_path).read)
            opts = {:position => :center}
            opts.merge!(i.width > 740 ? {:width => 740} : {})
            pdf.image img.file_path, opts
          end
        else
          pdf.text "Image for chart not found! (#{self.chart_image_key})"
        end
      end

      def set_y_legend(str)
        @chart[:y_legend] = { :text => str,
          :style =>  "{font-size: 12px; color: #888888}" }
      end

      private

      def set_element_types
        t = self.class.to_s.demodulize.underscore
        @chart[:elements].each {|e| e[:type] = t}
      end
    end
  end
end
