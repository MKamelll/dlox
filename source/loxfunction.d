module loxfunction;

import std.variant;

import loxcallable;
import stmtast;
import std.conv;
import loxerr;
import interpreter : Interpreter;
import environment : Environment;

class LoxFunction : LoxCallable
{
  private Stmt.Function declaration;
  private Environment closure;

  this(Stmt.Function declaration, Environment closure) {
    this.declaration = declaration;
    this.closure = closure;
  }

  override
  public int arity() {
    return to!int(declaration.params.length);
  }

  override
  public Variant call(Interpreter interpreter,
  Variant[] arguments) {
    Environment environment = new Environment(closure);

    for (int i = 0; i < declaration.params.length; i++) {
      environment.define(declaration.params[i].lexeme, arguments[i]);
    }

    try {
      interpreter.executeBlock(declaration.corpse, environment);
    } catch (Return returnValue) {
      return returnValue.value;
    }
    
    return Variant(null);
  }

  override
  public string toString() const {
    return "<fn " ~ declaration.name.lexeme ~ ">";
  }
}