=begin rdoc

= HasAndBelongsToManyVersioned

Provides a model with a has_and_belongs_to_many_versioned association,
which is basically a has_and_belongs_to_many association that handles
the versioned models correctly. That is, it the association fetches
only the models which are associated with the current version of the
association owner.

In addition, join fields can be included from the join table.

=end
module AssocExtensions
  module HasAndBelongsToManyVersioned
    REVERT_TO_ASSOCIATED_VERSION = false # set this in each model?

    def has_and_belongs_to_many_versioned(assoc, args={})
      base = self.to_s
      ass = assoc.to_s
      sin = ass.singularize

      ijf = ["#{sin}_version"]
      ijf += args[:include_join_fields] if args[:include_join_fields]
      cattr_accessor "#{assoc}_join_fields".to_sym
      self.send("#{assoc}_join_fields=", (args[:include_join_fields] || []))

      # add getters and setters for included join fields
      code = ""
      (self.send("#{assoc}_join_fields") || []).each do |jf|
        code += "
          define_method(:#{jf}) do
            if has_attribute?(:#{jf})
              ret = read_attribute(:#{jf})
            else
              ret = @#{jf}
            end
            (ret =~ /^[0-9]*$/) ? ret.to_i : ret
          end
          define_method(:#{jf}=) do |v|
            if has_attribute?(:#{jf})
              write_attribute(:#{jf}, v)
            else
              @#{jf} = v
            end
          end
          "
      end
      class_eval(code)

      # we need to add the getters and setters to the Version class too
      "#{assoc.to_s.classify}::Version".constantize.send(:class_eval, code)
      "#{assoc.to_s.classify}::Version".constantize.send(:class_eval,
        "def #{sin}_version=(args); end")

      ijf_str = ''
      ijf.each { |f| ijf_str += ", jt.#{f}" }

      join_table = [ass, base.tableize].sort.join('_')

      has_and_belongs_to_many assoc, :finder_sql => proc {
        finder_sql =
        "SELECT a.*"+ijf_str+" FROM "+ass+" a, "+
        "#{join_table} "+"jt WHERE a.id = jt."+sin+"_id AND "+
        "jt."+base.underscore+"_id = #{self.id} AND jt."+base.underscore+
        "_version = #{self.version}"
        finder_sql += " ORDER BY #{args[:order]}" unless args[:order].blank?
        finder_sql
      },
                                     :extend => AssocExtensions::Versioned

      # always revert if necessary
      if REVERT_TO_ASSOCIATED_VERSION
        after_find do |record|
          version_from_join_table = self["#{base.downcase}_version"].to_i
          if version_from_join_table and self.version != version_from_join_table
            self.revert_to(version_from_join_table)
            self.clear_association_cache
          end
        end
      end

      after_destroy do |record|
        connection.execute \
          "DELETE FROM #{join_table} WHERE #{base.underscore}_id=#{record.id}"
      end

      # make sure the association cache is always cleared
      alias_method "orig_#{assoc}".to_sym, assoc.to_sym
      define_method(assoc.to_sym) do
        clear_association_cache
        send "orig_#{assoc}"
      end
    end
  end

  module Versioned

    # Note: << doesn't do any updating of existing records or their
    # join fields - if something changes, a new version should always
    # be created.

    def <<(input_obs)
      input_obs = [input_obs] unless input_obs.is_a? Array

      ob_keys = ActiveSupport::OrderedHash.new
      ob_keys['id'] = "#{proxy_association.reflection.class_name.underscore}_id"
      ob_keys['version'] = "#{proxy_association.reflection.class_name.underscore}_version"
      proxy_association.owner.class.send("#{proxy_association.reflection.name}_join_fields").each do |f|
        ob_keys[f] = f
      end

      join_table = proxy_association.reflection.options[:join_table]

      # Add new records. Delete duplicates
      obs = input_obs.uniq
      obs = obs.select{|o| not current.include?(o)}
      return current unless obs.size > 0

      val_strings = get_val_strings(obs, ob_keys)

      ActiveRecord::Base.connection.execute(
         "INSERT INTO #{join_table} (#{proxy_association.owner.class.to_s.underscore}"+
         "_id,#{proxy_association.owner.class.to_s.underscore}_version,"+
         "#{ob_keys.values.join(',')}) VALUES #{val_strings.join(',')}"
        )
      current
    end
    alias_method :push, :<<

    # N.B. This marks objects deleted 'globally'
    def delete(obs)
      obs = [obs] unless obs.is_a? Array
      delete_ids obs.map(&:id)
    end

    def delete_ids(*args)
      # Disabled. causes unwanted behaviour when destroying
      true
    end

    def destroy(*args)
      raise "destroying not supported"
    end

    def count(*args)
      raise "count not suppported, use #size on result set."
    end

    protected

    def get_val_strings(obs, ob_keys)
      val_strings = []

      obs.each do |o|
        if proxy_association.reflection.class_name != o.class.to_s
          raise "Invalid type, expected #{proxy_association.reflection.class_name}, "+
                "got #{o.class.to_s}"
        end
        o.save! if o.new_record? # fail early if not valid
        vals = [proxy_association.owner.id.to_s, proxy_association.owner.version.to_s]
        raise "Association owner not saved" if proxy_association.owner.id.nil?

        ob_keys.each do |k,v|
          a_val = o.send(k)
          raise "nil #{k} for #{o.class.to_s} (id #{o.id})" unless a_val
          vals << a_val.to_s
        end
        val_strings << '('+ vals.join(',') + ')'
      end
      val_strings
    end

    def current
      proxy_association.owner.send proxy_association.reflection.table_name
    end

    def convert_query_to_proxy(sql)
      ret = sql.gsub(/#\{(.+?)\.(.+?)\}/) do |match|
        proxy_association.owner.send($2).to_s
      end
    end

    def do_query(sql)
      ret = find_by_sql(convert_query_to_proxy(sql))
    end
  end
end

module ActiveRecord
  class Base
    extend AssocExtensions::HasAndBelongsToManyVersioned
    def self.external_id_scope; :project; end
  end
end
