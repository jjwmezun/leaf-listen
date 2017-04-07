require( 'json' )
require( 'haml' )

module Autumn
  module AIO
    extend self

    # Main IO Functions
    def read_file( path )
      file = File.open( path )
      content = file.read()
      
      if ( File.extname( path ) == ".haml" )
        content = hamlize( content )
      end
      
      file.close()
      return content
    end
  
    def write_file( path, content )
      src_path_to_dist( path )
      writable = File.open( path, 'w' )
      writable << content
      writable.close()
    end
    
    def src_to_dist( path )
      write_file( path, read_file( path ) )
    end

    def delete_file( path )
      src_path_to_dist( path )
      File.delete( path )
    end
    
    def json_file( obj )
      content = read_file( "#{ Dir.pwd }/config.json" )
      content = JSON.parse( content )
      return content[ obj ]
    end

    def hamlize( content, locals = {} )
      engine = Haml::Engine.new( content )
      return engine.render( Object.new, locals )
    end

    def relative_path( path )
        relative_path = path.clone()
        relative_path.slice!( Dir.pwd )
        return relative_path
    end

    def get_file_transfers
      if ( not @@transfers )
        @@transfers = []
        @@transfers = json_file( "transfers" )
      end

      return @@transfers
    end

    
    
    private
      @@transfers = nil

      class IllogicalPath < StandardError
        def initialize( path )
          super( "Illogical src-dist path: #{ path }" )
        end
      end

      def src_path_to_dist( path )
        get_file_transfers().each do | type |
          from = Dir.pwd + type[ "from" ]
          if ( path.start_with?( from ) )
            to = Dir.pwd + type[ "to" ]
            return path.gsub!( from, to )
          end
        end

        raise IllogicalPath.new( path )
      end
  end
end