module interpreter;

import exprast;
import stmtast;
import loxer;
import std.variant;
import std.stdio;
import std.string;
import loxerr;
import stmtast;
import environment;

class Interpreter : Expr.Visitor, Stmt.Visitor
{
  Variant result;
  private Environment environment = new Environment();

  void interpret(Stmt[] statements) {
    try {
      foreach (statement; statements)
      {
        execute(statement);
      }
    } catch (RuntimeError error) {
      Loxerr.runtimeError(error);
    }
  }

  private Variant evaluate(Expr expr) {
    expr.accept(this);
    return result;
  }

  private void execute(Stmt stmt) {
    stmt.accept(this);
  }

  private string stringify(Variant v) {
    if (v.type == typeid(null)) return "nil";
    if (v.type == typeid(double)) {
      string text = v.toString();
      return text.chomp(".0");
    }
    return v.toString();
  }

  override
  public void visit(Stmt.Var stmt) {
    Variant value = null;
    if (stmt !is null) {
      value = evaluate(stmt.intializer);
    }

    environment.define(stmt.name.lexeme, value);
  }

  override
  public void visit(Expr.Assign expr) {
    Variant value = evaluate(expr.value);
    environment.assign(expr.name, value);
    result = value;
  }

  override
  public void visit(Expr.Variable expr) {
    result = environment.get(expr.name);
  }

  override
  public void visit(Stmt.Expression stmt) {
    evaluate(stmt.expression);
  }

  override
  public void visit(Stmt.Print stmt) {
    Variant value = evaluate(stmt.expression);
    writeln(stringify(value));
  }

  override
  public void visit(Expr.Literal expr) {
    result = expr.literal;
  }

  override
  public void visit(Expr.Grouping expr) {
    result = evaluate(expr.expression);
  }

  override
  public void visit(Expr.Unary expr) {
    auto right = evaluate(expr.right);

    switch (expr.operator.type) {
      case TokenType.BANG:
        result = !isTruthy(right);
        break;
      case TokenType.MINUS:
        checkNumberOperand(expr.operator, right);
        result = -right.get!double;
        break;
      default: break;
    }
  }

  private bool isTruthy(Variant v) {
    if (v.type == typeid(null)) return false;
    if (v.type == typeid(bool)) return v.get!bool;
    return true;
  }

  private void checkNumberOperand(Token operator, Variant operand) {
    if (operand.type == typeid(double)) return;
    throw new RuntimeError(operator, "Operand must be a number.");
  }

  override
  public void visit(Expr.Binary expr) {
    auto left = evaluate(expr.left);
    auto right = evaluate(expr.right);

    switch (expr.operator.type) {
      case TokenType.GREATER:
        checkNumberOperands(expr.operator, left, right);
        result = left.get!double > right.get!double;
        break;
      case TokenType.GREATER_EQUAL:
        checkNumberOperands(expr.operator, left, right);
        result = left.get!double >= right.get!double;
        break;
      case TokenType.LESS:
        checkNumberOperands(expr.operator, left, right);
        result = left.get!double < right.get!double;
        break;
      case TokenType.LESS_EQUAL:
        checkNumberOperands(expr.operator, left, right);
        result = left.get!double <= right.get!double;
        break;
      case TokenType.BANG_EQUAL:
        result = !isEqual(left, right);
        break;
      case TokenType.EQUAL_EQUAL:
        result = isEqual(left, right);
        break;
      case TokenType.MINUS:
        checkNumberOperands(expr.operator, left, right);
        result = left.get!double - right.get!double;
        break;
      case TokenType.PLUS:
        if ((left.type == typeid(double) && right.type == typeid(double))
           || (left.type == typeid(int) && right.type == typeid(int))) {
          result = left.get!double + right.get!double;
          break;
        }
        if (left.type == typeid(string) && right.type == typeid(string)) {
          result = left.get!string ~ right.get!string;
          break;
        }
        throw new RuntimeError(expr.operator, "Gimme either two numbers or two strings.");
      case TokenType.SLASH:
        checkNumberOperands(expr.operator, left, right);
        result = left.get!double / right.get!double;
        break;
      case TokenType.STAR:
        checkNumberOperands(expr.operator, left, right);
        result = left.get!double * right.get!double;
        break;
      default: break;
    }
  }

  private bool isEqual(Variant v1, Variant v2) {
    if (v1.type == typeid(null) && v2.type == typeid(null))
      return true;
    if (v1.type == typeid(null)) return false;
    return v1 == v2;
  }

  private void checkNumberOperands(Token operator, Variant left, Variant right) {
    if (left.type == typeid(double) && right.type == typeid(double)) return;
    throw new RuntimeError(operator, "Operands must be numbers.");
  }

}