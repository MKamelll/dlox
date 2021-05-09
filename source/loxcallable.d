module loxcallable;

import std.variant;
import interpreter;

interface LoxCallable
{
  Variant call(Interpreter interpreter, Variant[] arguments);
  int arity();
}