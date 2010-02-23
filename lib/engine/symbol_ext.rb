class Symbol
    # A generalized conversion of a method name
    # to a proc that runs the method.
    # From the pickaxe via http://eli.thegreenplace.net/2006/04/18/understanding-ruby-blocks-procs-and-methods/.
    def to_proc
        lambda {|x, *args| x.send(self, *args)}
    end
end
