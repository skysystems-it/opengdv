# A class that captures the structure of the model, i.e.  that stores the
# grammar for records and subobjects given in the model classes
module GDV::Model
    class Grammar

        # The fields against which we can match records
        MATCH_OPTS = [ :satz, :sparte ]

        # The options for the various rules. The keys also define what
        # rules are available
        RULE_OPTS = {
            :one => MATCH_OPTS,
            :maybe => MATCH_OPTS,
            :star => MATCH_OPTS,
            :object => [ :class ],
            :objects => [ :class ],
            :skip_until => MATCH_OPTS,
            :error => [ :test, :message ]
        }

        # A single rule in the grammar
        class Rule
            attr_reader :kind, :name, :opts

            def initialize(kind, name, opts)
                @kind = kind
                @name = name
                @opts = opts
                unless RULE_OPTS.keys.include?(kind)
                    raise "Unknown grammar rule '#{kind}'"
                end
                opts.keys.each do |o|
                    unless RULE_OPTS[kind].include?(o)
                        raise "Unknown option '#{o}' for rule #{kind} #{name}"
                    end
                end
            end

            def run(runnable)
                runnable.send(@kind, @name, @opts)
            end

            def bind(klass)
                # :attr_reader is private
                klass.send(:attr_reader, @name) unless @name == :error
            end
        end

        attr_reader :klass

        # Create a new grammar. The rules for the grammar come from
        # evaluating the block against +self+
        def initialize(klass, &block)
            @rules = []
            @klass = klass
            instance_eval &block
        end

        # Run the grammar against a runnable. A runnable must define a
        # method for every kind of rule; those methods most take the name
        # of the entry together with an option hash as arguments
        def run(runnable)
            @rules.each { |r| r.run(runnable) }
        end

        # Add a rule of the given kind under the given name and with the
        # given options
        def new_rule(kind, name, opts)
            rule = Rule.new(kind, name, opts)
            @rules << rule
            rule.bind(klass) if rule.name
        end

        # Accept one record that matches the conditions in +opts+ and store
        # it in the attribute +name+
        def one(name, opts)
            new_rule(:one, name, opts)
        end

        # Accept none or one record that matches the conditions in +opts+
        # and store it in the attribute +name+
        def maybe(name, opts)
            new_rule(:maybe, name, opts)
        end

        # Accept an arbitrary number, including none, of records that match
        # the conditions in +opts+ and store an array of the matching
        # records in the attribute +name+.
        def star(name, opts)
            new_rule(:star, name, opts)
        end

        # Accept an optional object of the given +klass+ and store it in
        # the attribute +name+.
        def object(name, klass)
            new_rule(:object, name, :class => klass)
        end

        # Accept an arbitrary number of objects, including none, of the
        # given +klass+ and store an array of the matching objects in the
        # attribute +name+
        def objects(name, klass)
            new_rule(:objects, name, :class => klass)
        end

        # Skip records until we find one that matches +cond+. Skipped
        # records are silently discarded
        def skip_until(cond)
            new_rule(:skip_until, nil, cond)
        end

        def error(msg, &block)
            new_rule(:error, nil, :message => msg, :test => block)
        end
    end
end