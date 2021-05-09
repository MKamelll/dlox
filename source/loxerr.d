module loxerr;

import std.stdio;
import std.variant;
import std.conv;
import std.array;
import loxer : Token, TokenType;

static bool hadRuntimeError = false;

class Return : Exception
{
  Variant value;
  this(Variant value , string msg = "", string file = __FILE__, size_t line = __LINE__,
  Throwable nextInChain = null)
  {
    super(msg, file, line, nextInChain);
    this.value = value;
  }
}


class RuntimeError : Exception
{
  Token token;
  this(Token token, string msg, string file = __FILE__, size_t line = __LINE__,
  Throwable nextInChain = null) pure nothrow @nogc @safe
  {
    super(msg, file, line, nextInChain);
    this.token = token;
  }
}

class ParseError : Exception
{
  this(string msg = "", string file = __FILE__,
   size_t line = __LINE__,
    Throwable nextInChain = null) pure nothrow @nogc @safe
  {
    super(msg, file, line, nextInChain);
  }
}

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

    static void runtimeError(RuntimeError error) {
      stderr.writeln(error.message ~ 
      "\n[line " ~ to!string(error.token.line) ~ "]");
      hadRuntimeError = true;
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