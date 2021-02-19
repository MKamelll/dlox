module loxast;

import std.variant;
import loxer;

// using void as return type of visit and accept
// as D's generics are compile time templates
// other ways would be tagged unions (std.variant in D)
// or tag based dispatch
// answered by: Paul Backus
// https://forum.dlang.org/post/ardcugqzjcxbtqqmvlxa@forum.dlang.org

interface Visitor
{
  void visit(Expr.Binary expr);
  void visit(Expr.Literal expr);
  void visit(Expr.Unary expr);
  void visit(Expr.Grouping expr);
}

abstract class Expr {

  abstract void accept(Visitor visitor);

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
    
    override
    void accept(Visitor visitor) {
      visitor.visit(this);
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
    
    override
    void accept(Visitor visitor) {
      visitor.visit(this);
    }
  }

  static class Literal : Expr
  {
    LexLiteral literal;
    this(LexLiteral literal) {
      this.literal = literal;
    }
    
    override
    void accept(Visitor visitor) {
      visitor.visit(this);
    }
  }

  static class Grouping : Expr
  {
    Expr expression;
    this(Expr expression) {
      this.expression = expression;
    }
    
    override
    void accept(Visitor visitor) {
      visitor.visit(this);
    }
  }
}

class AstPrinter : Visitor
{
  string result;
  
  string print(Expr expr) {
    expr.accept(this);
    return result;
  }
 
  override
  void visit(Expr.Binary expr) {
    result = parenthesize(expr.operator.lexeme,
                        expr.left, expr.right);
  }

  override
  void visit(Expr.Literal expr) {
    if (!expr.literal.hasValue)
      result = "nil";
    else result = lexLiteralStr(expr.literal);
  }

  override 
  void visit(Expr.Unary expr) {
    result = parenthesize(expr.operator.lexeme, expr.right);
  }

  override
  void visit(Expr.Grouping expr) {
    result = parenthesize("group", expr.expression);
  }

  private string parenthesize(string name, Expr[] exprs...) {
    string strParen;
    strParen ~= "(" ~ name;
    foreach (expr; exprs)
    {
      expr.accept(this);
      strParen ~= " " ~ result;
    }
    strParen ~= ")";

    return strParen;
  }
}