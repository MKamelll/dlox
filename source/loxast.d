module loxast;

import std.variant;
import loxer;

interface Visitor(T)
{
  T visit(Expr.Binary expr);
  T visit(Expr.Literal expr);
  T visit(Expr.Unary expr);
  T visit(Expr.Grouping expr);
}

abstract class Expr {

  string accept(Visitor!string visitor);

  static class Binary : Expr
  {
    Expr left;
    Token operator;
    Expr right;
    this(Expr left, Token operator, Expr right) {
      this.left = left;
      this.operator = operator;
      this.right = right;
    }
    override string accept(Visitor!string visitor) {
      return visitor.visit(this);
    }
  }

  static class Unary : Expr
  {
    Token operator;
    Expr right;
    this(Token operator, Expr right) {
     this.operator = operator;
      this.right = right;
    }
    override string accept(Visitor!string visitor) {
      return visitor.visit(this);
    }
  }

  static class Literal : Expr
  {
    LexLiteral literal;
    this(LexLiteral literal) {
      this.literal = literal;
    }
    override string accept(Visitor!string visitor) {
      return visitor.visit(this);
    }
  }

  static class Grouping : Expr
  {
    Expr expression;
    this(Expr expression) {
      this.expression = expression;
    }
    override string accept(Visitor!string visitor) {
      return visitor.visit(this);
    }
  }
}

class AstPrinter : Visitor!string
{
  string print(Expr expr) {
    return expr.accept(this);
  }
 
  string visit(Expr.Binary expr) {
    return parenthesize(expr.operator.lexeme,
                        expr.left, expr.right);
  }

  string visit(Expr.Literal expr) {
    if (!expr.literal.hasValue) return "nil";
    return lexLiteralStr(expr.literal);
  }

  string visit(Expr.Unary expr) {
    return parenthesize(expr.operator.lexeme, expr.right);
  }

  string visit(Expr.Grouping expr) {
    return parenthesize("group", expr.expression);
  }

  string parenthesize(string name, Expr[] exprs...) {
    string result;
    result ~= "(" ~ name;
    foreach (expr; exprs)
    {
      result ~= " " ~ expr.accept(this);
    }
    result ~= ")";
    
    return result;
  }
}
/* test
void main() {
  import std.stdio : writeln;
  
  auto b = new Expr.Literal(LexLiteral(123));

  writeln(new AstPrinter().print(b));
}*/