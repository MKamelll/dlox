module environment;

import std.variant;
import loxer;
import loxerr;

// A type to represent a map for the variables and
// their values.
class Environment
{
  private Variant[string] values;

  void define(string name, Variant value) {
    values[name] = value;
  }

  Variant get(Token name) {
    if (name.lexeme in values) {
      return values[name.lexeme];
    }
    throw new RuntimeError(name,
      "Undefined variable '" ~ name.lexeme ~ "'.");
  }

  void assign(Token name, Variant value) {
    if (name.lexeme in values) {
      values[name.lexeme] = value;
    } else {
      throw new RuntimeError(name, "Undefined variable '" ~ name.lexeme ~ "'.");
    }
  }
}