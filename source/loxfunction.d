module loxfunction;

import std.variant;

import loxcallable;
import stmtast;
import std.conv;
import interpreter : Interpreter;
import environment : Environment;

class LoxFunction : LoxCallable
{
  private Stmt.Function declaration;

  this(Stmt.Function declaration) {
    this.declaration = declaration;
  }

  override
  public int arity() {
    return to!int(declaration.params.length);
  }

  override
  public Variant call(Interpreter interpreter,
  Variant[] arguments) {
    Environment environment = new Environment(interpreter.globals);

    for (int i = 0; i < declaration.params.length; i++) {
      environment.define(declaration.params[i].lexeme, arguments[i]);
    }

    interpreter.executeBlock(declaration.corpse, environment);
    return Variant(null);
  }

  override
  public string toString() const {
    return "<fn " ~ declaration.name.lexeme ~ ">";
  }
}