require( "listen" )
require_relative( 'autumn_io' )

module Autumn
  module Listener
    extend self

    def start
      check_files()
      listen()
    end
    
    # Lazy way to check changes from when program wasn't running.
    def check_files
      puts "Checking files..."
            
      AIO.get_file_transfers().each do | type |
        dist_dir = Dir.pwd + type[ "to" ]
        src_dir  = Dir.pwd + type[ "from" ]
        
        # Clear all dist.
        Dir.glob( "#{ dist_dir }*" ) do | df |
          File.delete( df )
        end
        
        # Recompile all src
        Dir.glob( "#{ src_dir }*" ) do | sf |
          AIO.src_to_dist( sf )
        end
      end
    end
    
    # Main event loop
    def listen
      puts "Listening..."
      listener = Listen.to( '' ) do | modified, added, removed |

        changes = [
          { type: :modified, files: modified },
          { type: :added,    files: added    },
          { type: :removed,  files: removed  }
        ]

        changes.each do | change |
          change[ :files ].each do | f |
            if ( in_right_dir?( f ) )
              if ( change[ :type ] == :removed )
                remove( f )
              elsif ( change[ :type ] == :modified or change[ :type ] == :added )
                add_or_modify( f )
              end
              puts "Listening..."
            end
          end
        end

      end

      listener.start() # not blocking

      sleep()
    end



    private
      def add_or_modify( path )
        puts( "CHANGED: #{ path }" )
        AIO.src_to_dist( path )
      end

      def remove( path )
        puts( "DELETED: #{ path }" )
        AIO.delete_file( path )
      end

      def in_right_dir?( path )
        relative_path = AIO.relative_path( path )

        AIO.get_file_transfers().each do | type |
          right_dir = type[ "from" ]
          if ( relative_path.start_with?( right_dir ) )
            return true
          end
        end

        return false
      end
  end
end