# frozen_string_literal: true

module LightRecord
  extend self

  # Create LightRecord class based on klass argument
  # Used internally by scope#light_records and scope#light_records_each
  #
  # @param klass [Class] ActiveRecord model
  # @param fields [Array] list of fields, will be used to define attribute methods
  # @return new class base on klass argument but extended with LightRecord methods
  #
  def build_for_class(klass, fields)
    new_klass = Class.new(klass) do
      self.table_name = klass.table_name
      self.inheritance_column = nil

      extend LightRecord::RecordAttributes

      define_fields(fields)

      def initialize(data)
        @attributes = data
        @readonly = true
        @association_cache = {}
        @primary_key = self.class::LIGHT_RECORD_PRIMARY_KEY_CACHE
        #init_internals
      end

      def self.model_name
        self.superclass.model_name
      end

      def read_attribute_before_type_cast(attr_name)
        @attributes[attr_name.to_sym]
      end

      def self.subclass_from_attributes?(attrs)
        false
      end

      def has_attribute?(attr_name)
        @attributes.has_key?(attr_name.to_sym)
      end

      def read_attribute(attr_name)
        @attributes[attr_name.to_sym]
      end

      def _read_attribute(attr_name)
        @attributes.fetch(attr_name.to_sym) { |n| yield n if block_given? }
      end

      def [](attr_name)
        @attributes[attr_name.to_sym]
      end

      def attributes
        @attributes
      end

      # to avoid errors when try saving data
      def remember_transaction_record_state
        @new_record ||= false
        @destroyed ||= false
        @_start_transaction_state ||= {level: 0}
        super
      end

      def sync_with_transaction_state
        nil
      end

      def new_record?
        false
      end

      # For Rails < 5.1
      # Assign without type casting, no support for alias, sorry
      def write_attribute_with_type_cast(attr_name, value, should_type_cast)
        @attributes[attr_name.to_sym] = value
      end

      # For Rails >= 5.1
      # Assign without type casting, no support for alias, sorry
      if ActiveRecord.version >= Gem::Version.new("5.1.0")
        def write_attribute(attr_name, value)
          attr_name = attr_name.to_sym
          attr_name = self.class.primary_key if attr_name == :id && self.class.primary_key
          @attributes[attr_name] = value
          value
        end

        def raw_write_attribute(attr_name, value) # :nodoc:
          @attributes[attr_name.to_sym] = value
          value
        end
      end

      ## For Rails 5.2
      def id_in_database
        attributes[self.class.primary_key.to_sym]
      end

      # For Rails >= 6.0
      if ActiveRecord.version >= Gem::Version.new("6.0.0")
        def restore_transaction_record_state(force_restore_state = false)
          # nothing
        end

        def _has_attribute?(attr_name)
          has_attribute?(attr_name)
        end
      end

      # For Rails >= 7.0
      if ActiveRecord.version >= Gem::Version.new("7.0.0")
        def update_columns(attributes)
          unless @attributes.respond_to?(:write_cast_value)
            @attributes.define_singleton_method(:write_cast_value) do |k, v|
              self[k.to_sym] = v
            end
          end
          super
        end

        def clear_attribute_change(k)
          # nothing
        end
      end

      def reload
        super
        @attributes = @attributes.to_h.symbolize_keys

        self
      end

      private
        def write_attribute_without_type_cast(attr_name, value)
          @attributes[attr_name.to_sym] = value
        end

        def clear_aggregation_cache
          if defined?(@aggregation_cache) && @aggregation_cache
            super
          end
        end
    end

    # for rails 6
    new_klass.const_set(:LIGHT_RECORD_PRIMARY_KEY_CACHE, klass.primary_key)

    if klass.const_defined?(:LightRecord, false)
      new_klass.send(:prepend, klass::LightRecord)
      if klass::LightRecord.respond_to?(:included)
        klass::LightRecord.included(new_klass)
      end
    elsif klass.superclass.const_defined?(:LightRecord, false)
      new_klass.send(:prepend, klass.superclass::LightRecord)
      if klass.superclass::LightRecord.respond_to?(:included)
        klass.superclass::LightRecord.included(new_klass)
      end
    end

    new_klass
  end

  # ActiveRecord extension for class methods
  # Defines klass.define_fields
  # Overrides klass.column_names and klass.define_attribute_methods
  module RecordAttributes
    def define_fields(fields)
      @fields ||= []

      fields.each do |field|
        field = field.to_sym
        @fields << field
        define_method(field) do
          @attributes[field]
        end

        # to avoid errors when try saving data
        define_method("#{field}=") do |value|
          @attributes[field] = value
        end
      end

      # ActiveRecord make method :id refers to primary key, even there is no column "id"
      if !@fields.include?(:id) && primary_key.present?
        define_method(:id) do
          @attributes[self.class.primary_key.to_sym]
        end
      end
    end

    # used in Record#respond_to?
    def define_attribute_methods
    end

    # Active record keep it as strings, but I keep it as symbols
    def column_names
      @column_names ||= @fields.map(&:to_s)
    end
  end

  # Create LightRecord class based on klass argument
  def base_extended(klass)
    @base_extended ||= {}
    if @base_extended[klass]
      return @base_extended[klass]
    end

    @base_extended[klass] = LightRecord.build_for_class(klass, klass.column_names)
  end

  module RelationMethods

    # Executes query and return array of light object (model class extended by LightRecord)
    def light_records(options = {})
      sql = self.to_sql

      options = {
        stream: false, symbolize_keys: true, cache_rows: false, as: :hash,
        database_timezone: (
          ActiveRecord.respond_to?(:default_timezone) ?
          ActiveRecord.default_timezone :
          ActiveRecord::Base.default_timezone
        )
      }.merge(options)

      result = _light_record_execute_query(connection, sql, options.except(:set_const))

      klass = LightRecord.build_for_class(self.klass, result.fields)

      if options[:set_const]
        self.klass.const_set(:"LR_#{Time.now.to_i}", klass)
      end

      need_symbolize_keys = defined?(PG::Result) && result.is_a?(PG::Result)

      records = []
      result.each do |row|
        row.symbolize_keys! if need_symbolize_keys
        records << klass.new(row)
      end

      return records
    end

    # Same as `#light_records` but iterates through result set and call block for each object
    # this uses less memroy because it creates objects one-by-one
    # it uses stream feature of mysql client
    def light_records_each(options = {})
      conn = ActiveRecord::Base.connection_pool.checkout
      sql = self.to_sql

      options = {
        stream: true, symbolize_keys: true, cache_rows: false, as: :hash,
        database_timezone: (
          ActiveRecord.respond_to?(:default_timezone) ?
          ActiveRecord.default_timezone :
          ActiveRecord::Base.default_timezone
        )
      }.merge(options)

      result = _light_record_execute_query(conn, sql, options.except(:set_const))

      klass = LightRecord.build_for_class(self.klass, result.fields)

      if options[:set_const]
        self.klass.const_set(:"LR_#{Time.now.to_i}", klass)
      end

      if defined?(PG::Result) && result.is_a?(PG::Result)
        begin
          result.stream_each do |row|
            row.symbolize_keys!
            yield klass.new(row)
          end
        rescue => error
          conn.raw_connection.get_last_result
          throw error
        ensure
          result.clear
        end
      else
        result.each do |row|
          yield klass.new(row)
        end
      end
    ensure
      ActiveRecord::Base.connection_pool.checkin(conn)
    end

    private def _light_record_execute_query(connection, sql, options)
      client = connection.raw_connection

      if client.class.to_s == 'PG::Connection'
        if options[:stream]
          connection.send(:log, sql, "LightRecord - #{self.klass}") do
            ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
              client.send_query(sql)
              client.set_single_row_mode
              result = client.get_result
              result.check
              result
            end
          end
        else
          connection.execute(sql, "LightRecord - #{self.klass}")
        end
      else
        connection.send(:log, sql, "LightRecord - #{self.klass}") do
          client.query(sql, options)
        end
      end
    end

  end

end

ActiveRecord::Relation.send(:include, LightRecord::RelationMethods)
