"""Log"""
import sys
import os

class Log(dict):
    """Log to write details to."""

    def __init__(self, file = None):
        dict.__init__(self, file=file) # to support JSON serialization.
        if file is not None:
            self._log = open(file, "w")
        else:
            self._log = None

    def println(self, msg):
        if len(msg) > 0: self.print(msg)
        self.print("\n")

    def print(self, msg):
        sys.stdout.write(msg)
        sys.stdout.flush()

        if self._log is not None:
            self._log.write(msg)
            self._log.flush()

    def error(self, msg):
        self.print("ERROR: ")
        self.println(msg)

    def warn(self, msg):
        self.print("WARNING: ")
        self.println(msg)

    def file(self):
        return self._log

    def close(self):
        if self._log is not None:
            self._log.close()
