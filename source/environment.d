module environment;

import std.variant;
import loxer;
import loxerr;

// A type to represent a map for the variables and
// their values.
class Environment
{
  private Variant[string] values;
  private Environment enclosing;

  this() {
    enclosing = null;
  }
  
  this(Environment enclosing) {
    this.enclosing = enclosing;
  }

  void define(string name, Variant value) {
    values[name] = value;
  }

  Variant get(Token name) {
    if (name.lexeme in values) {
      return values[name.lexeme];
    }

    if (enclosing !is null) return enclosing.get(name);
    
    throw new RuntimeError(name,
      "Undefined variable '" ~ name.lexeme ~ "'.");
  }

  Variant getAt(int distance, string name) {
    return ancestor(distance).values[name];
  }

  void assignAt(int distance, Token name, Variant value) {
    ancestor(distance).values[name.lexeme] = value;
  }

  Environment ancestor(int distance) {
    Environment environment = this;
    for (int i = 0; i < distance; i++) {
      environment = environment.enclosing;
    }

    return environment;
  }

  void assign(Token name, Variant value) {
    if (name.lexeme in values) {
      values[name.lexeme] = value;
      return;
    }
    
    if (enclosing !is null) {
      enclosing.assign(name, value);
      return;
    }
    
    throw new RuntimeError(name, "Undefined variable '" ~ name.lexeme ~ "'.");
    
  }
}