# The get_instance method should return an instance which has
# a new_verioned_child (singleton) method defined which creates a valid child
# (if has_and_belongs_to_many_versioned childs)

shared_examples_for "versioned" do
  def join_table_rows(host, assoc)
    jt = [host.class.to_s.tableize, assoc].sort.join('_')
    rows = ActiveRecord::Base.connection.select_all \
      "select * from #{jt} WHERE #{host.class.to_s.underscore}_id=#{host.id}"
    rows.size
  end
  
  it "should store old version of field data" do
    @host = get_instance

    # select a text/string field to test versioning on
    a_field = @host.class.columns.detect do |c| 
      [:text, :string].include?(c.type)
    end.name
    
    first_name = @host.send(a_field)
    @host.versions.size.should == 1
    @host.update_attribute(a_field, 'second field version')
    @host.versions.size.should == 2
    @host.versions.first.send(a_field).should == first_name
    @host.versions[1].send(a_field).should == 'second field version'
  end
  
  it "should store old version of association configuration" do
    @host = get_instance
    if @host.respond_to?(:versioned_assoc_name)
      versioned_assoc = @host.send(:versioned_assoc_name)
      @host.send(versioned_assoc) << @host.new_versioned_child
      @host.send(versioned_assoc).size.should == 1
      @host.save!
      @host.version.should == 2
      @host.send(versioned_assoc).size.should == 0
      @host.send(versioned_assoc) << ([@host.new_versioned_child, 
                                       @host.new_versioned_child, 
                                       @host.new_versioned_child])
      @host.send(versioned_assoc).size.should == 3
      @host.revert_to(1)
      @host.send(versioned_assoc).size.should == 1
    end
  end
  
  describe "#destroy" do
    it "should clean (versioned) join table" do
      @host = get_instance
      if @host.respond_to?(:versioned_assoc_name)
        versioned_assoc = @host.send(:versioned_assoc_name)
        @host.send(versioned_assoc) << @host.new_versioned_child
        @host.save!
        @host.send(versioned_assoc) << @host.new_versioned_child
        join_table_rows(@host, versioned_assoc).should == 2
        @host.destroy
        join_table_rows(@host, versioned_assoc).should == 0
      end
    end
    
    it "should clean (versioned) join table, a more complex example" do
      @host = get_instance
      if @host.respond_to?(:versioned_assoc_name)
        versioned_assoc = @host.send(:versioned_assoc_name)
        @host.send(versioned_assoc) << @host.new_versioned_child
        @host.save!
        @host2 = get_instance
        @host2.send(versioned_assoc) << @host2.new_versioned_child
        @host2.send(versioned_assoc) << @host2.new_versioned_child
        join_table_rows(@host, versioned_assoc).should == 1
        join_table_rows(@host2, versioned_assoc).should == 2
        @host.destroy
        join_table_rows(@host, versioned_assoc).should == 0
        join_table_rows(@host2, versioned_assoc).should == 2
      end
    end
    
    # just in case. should be tested by acts_as_versioned plugin tests though
    it "should clean versions table" do
      @host = get_instance
      @host.save!
      vtable = @host.class.versioned_table_name
      rows = ActiveRecord::Base.connection.select_all \
        "select * from #{vtable} where #{@host.class.to_s.underscore}_id=#{@host.id}"
      rows.size.should == 2
      @host.destroy
      rows = ActiveRecord::Base.connection.select_all \
        "select * from #{vtable} where #{@host.class.to_s.underscore}_id=#{@host.id}"
      rows.size.should == 0
    end
  end
  
  it "should not store duplicate entries for association" do
    @host = get_instance
    if @host.respond_to?(:versioned_assoc_name)
      versioned_assoc = @host.send(:versioned_assoc_name)
      # case 1, in same array
      @host = get_instance
      c1 = @host.new_versioned_child
      @host.send(versioned_assoc) << [c1,c1]
      @host.send(versioned_assoc).size.should == 1
      
      # case 2, in sequence
      @host = get_instance
      c1 = @host.new_versioned_child
      @host.send(versioned_assoc) << c1
      @host.send(versioned_assoc) << c1
      @host.send(versioned_assoc).size.should == 1
    end
  end
  
  it "should NOT(!) revert version associated models to their associated version" do
    @host = get_instance
    if @host.respond_to?(:versioned_assoc_name)
      versioned_assoc = @host.send(:versioned_assoc_name)
      ch = @host.new_versioned_child
      ch.save
      ch.version.should == 1

      @host.send(versioned_assoc) << ch
      
      ch.save!
      ch.version.should == 2
      
      children = @host.send(versioned_assoc)
      children.size.should == 1
      children.first.version.should == 2 # !!!!
    end
  end
  
  it "should have working #versioned_assoc_ids, if versioned_assoc" do
    @host = get_instance
    if @host.respond_to?(:versioned_assoc_name)
      versioned_assoc = @host.send(:versioned_assoc_name)
      ch = @host.new_versioned_child
      @host.send(versioned_assoc) << ch
      ch2 = @host.new_versioned_child
      @host.send(versioned_assoc) << ch2
      @host.send("#{versioned_assoc.singularize}_ids").size.should == 2
      (@host.send("#{versioned_assoc.singularize}_ids") | [ch.id, ch2.id]).
        size.should == 2
      
      @host.save!
      @host.reload
      @host.send("#{versioned_assoc.singularize}_ids").\
        should == []
      
      ch3 = @host.new_versioned_child
      @host.send(versioned_assoc) << ch3
      @host.send("#{versioned_assoc.singularize}_ids").\
        should == [ch3.id]
    end
  end
  
end
