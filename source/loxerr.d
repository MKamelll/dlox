module loxerr;

import std.stdio;
import std.conv;
import std.array;

class Loxerr
{
    static void error(int line, string message) {
        report(line, "", message);
    }

    private static void report(int line, string where,
    string message)
    {
        string outMessage = "[Line " ~ to!string(line) ~
        "] Error" ~ where ~ ": " ~ message;
        string border = replicate("#", outMessage.length);
        stderr.writeln(border ~ "\n" ~ outMessage ~ "\n" ~ border);
    }
}