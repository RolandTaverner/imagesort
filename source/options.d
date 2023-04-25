module options;

// Options holds options values
struct Options {
    bool execute = false;
    bool verbose = false;
    bool removeDups = false;
    void verboseMsg(void delegate() f) const {
        if (verbose) {
            f();
        }
    }
}
