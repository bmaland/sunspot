require File.join(File.dirname(__FILE__), 'test_helper')

class TestIndexer < Test::Unit::TestCase
  include RR::Adapters::TestUnit

  before do
    stub(Solr::Connection).new { connection }
  end

  describe 'when indexing an object' do
    after do
      Sunspot.index post
    end

    test 'should index id and type' do
      connection.add(hash_including(:id => "Post:#{post.id}", :type => ['Post', 'BaseClass']))
    end

    test 'should index text' do
      post :title => 'A Title', :body => 'A Post'
      connection.add(hash_including(:title_text => 'A Title', :body_text => 'A Post'))
    end

    test 'should correctly index a string attribute field' do 
      post :title => 'A Title'
      connection.add(hash_including(:title_s => 'A Title'))
    end

    test 'should correctly index an integer attribute field' do
      post :blog_id => 4
      connection.add(hash_including(:blog_id_i => '4'))
    end

    test 'should correctly index a float attribute field' do
      post :average_rating => 2.23
      connection.add(hash_including(:average_rating_f => '2.23'))
    end

    test 'should allow indexing by a multiple-value field' do
      post :category_ids => [3, 14]
      connection.add(hash_including(:category_ids_im => ['3', '14']))
    end

    test 'should correctly index a time field' do
      post :published_at => Time.parse('1983-07-08 05:00:00 -0400')
      connection.add(hash_including(:published_at_d => '1983-07-08T09:00:00Z'))
    end

    test 'should correctly index a virtual field' do
      post :title => 'The Blog Post'
      connection.add(hash_including(:sort_title_s => 'blog post'))
    end

    test 'should correctly index a field that is defined on a superclass' do
      Sunspot.setup(BaseClass) { string :author_name }
      post :author_name => 'Mat Brown'
      connection.add(hash_including(:author_name_s => 'Mat Brown'))
    end
  end

  test 'should throw a NoMethodError only if a nonexistent type is defined' do
    lambda { Sunspot.setup(Post) { string :author_name }}.should_not raise_error
    lambda { Sunspot.setup(Post) { bogus :journey }}.should raise_error(NoMethodError)
  end

  test 'should throw a NoMethodError if a nonexistent field argument is passed' do
    lambda { Sunspot.setup(Post) { string :author_name, :bogus => :argument }}.should raise_error(ArgumentError)
  end

  test 'should throw an ArgumentError if an attempt is made to index an object that has no configuration' do
    lambda { Sunspot::Indexer.add(Time.now) }.should raise_error(ArgumentError)
  end

  test 'should throw an ArgumentError if single-value field tries to index multiple values' do
    lambda do
      Sunspot.setup(Post) { string :author_name }
      Sunspot::Indexer.add(post(:author_name => ['Mat Brown', 'Matthew Brown']))
    end.should raise_error(ArgumentError)
  end

  private

  def connection
    @connection ||= mock!
  end

  def post(attrs = {})
    @post ||= Post.new(attrs)
  end
end