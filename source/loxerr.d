module loxerr;

import std.stdio;
import std.conv;
import std.array;
import loxer : Token, TokenType;


class Loxerr
{
    static void error(int line, string message) {
        report(line, "", message);
    }

    static void error(Token token, string message) {
      if (token.type == TokenType.EOF) {
        report(token.line, " at end", message);
      } else {
        report(token.line, " at '" ~ token.lexeme ~ "'", message);
      }
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