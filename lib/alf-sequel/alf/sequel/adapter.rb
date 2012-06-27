module Alf
  module Sequel
    #
    # Specialization of Alf::Adapter to distribute Sequel datasets
    #
    class Adapter < ::Alf::Adapter

      class << self

        # (see Alf::Adapter.recognizes?)
        #
        # @return true if args contains one String that can be interpreted as
        # a valid database uri, false otherwise
        def recognizes?(args)
          return false unless args.size == 1
          require 'uri'
          if (arg = args.first).is_a?(String)
            uri = URI::parse(arg)
            !!uri.scheme
            return true if !!uri.scheme
          end
          looks_a_sqlite_file?(arg)
        rescue ::URI::Error
          false
        end

        # Returns trus if `f` looks like a sqlite file
        def looks_a_sqlite_file?(f)
          return false unless Tools.pathable?(f)
          path = Tools.to_path(f)
          path.file? and ['db', 'sqlite', 'sqlite3'].include?(path.ext)
        end

      end # class << self

      # Creates an Adapter instance
      def initialize(uri, options = {})
        @uri = self.class.looks_a_sqlite_file?(uri) ? "#{sqlite_protocol}://#{uri}" : uri
        @options = options
      end

      def sqlite_protocol
        defined?(JRUBY_VERSION) ? "jdbc:sqlite" : "sqlite"
      end

      # (see Alf::Adapter#dataset)
      def dataset(name)
        conn = connect
        raise NoSuchDatasetError, "No such table `#{name}`" unless conn.table_exists?(name)
        Iterator.new(conn[name])
      end

      def ping
        connect
        @db.test_connection
      end

      private

      # Creates a database connection
      def connect
        @db ||= begin
          Alf::Tools::friendly_require('sequel')
          ::Sequel.connect(@uri, @options)
        end
      end

      Alf::Adapter.register(:sequel, self)
    end # class Adapter
  end # module Sequel
end # module Alf
