module stat;

enum StatField { ExistingDirs, NewDirs, FilesToExistingDirs, FilesToNewDirs};

interface IStatCounter {
    void increment(const StatField f);
}

class StatCounter : IStatCounter {
    int[StatField] fields;

    void increment(const StatField f) {
        ++fields[f];
    }

    int getValue(const StatField f) {
        const int *val = f in fields;
        return val != null ? *val : 0;
    }
}