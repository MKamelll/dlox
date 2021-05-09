module exprast;

import std.variant;
import loxer;

// using void as return type of visit and accept
// as D's generics are compile time templates
// other ways would be discriminated unions (std.variant in D)
// or tag based dispatch
// answered by: Paul Backus
// https://forum.dlang.org/post/ardcugqzjcxbtqqmvlxa@forum.dlang.org

abstract class Expr {

  interface Visitor
  {
    void visit(Expr.Binary expr);
    void visit(Expr.Literal expr);
    void visit(Expr.Unary expr);
    void visit(Expr.Grouping expr);
    void visit(Expr.Variable expr);
    void visit(Expr.Assign expr);
    void visit(Expr.Logical expr);
    void visit(Expr.Call expr);
  }

  abstract void accept(Expr.Visitor visitor);

  static class Call : Expr {
    Expr callee;
    Token paren;
    Expr[] arguments;

    this(Expr callee, Token paren, Expr[] arguments) {
      this.callee = callee;
      this.paren = paren;
      this.arguments = arguments;
    }

    override
    void accept(Expr.Visitor visitor) {
      visitor.visit(this);
    }
  }

  static class Logical : Expr {
    Expr left;
    Token operator;
    Expr right;

    this(Expr left, Token operator, Expr right) {
      this.left = left;
      this.operator = operator;
      this.right = right;
    }

    override
    void accept(Expr.Visitor visitor) {
      visitor.visit(this);
    }
  }

  static class Assign : Expr
  {
    Token name;
    Expr value;
    this(Token name, Expr value) {
      this.name = name;
      this.value = value;
    }

    override
    void accept(Expr.Visitor visitor) {
      visitor.visit(this);
    }
  }

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
    void accept(Expr.Visitor visitor) {
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
    void accept(Expr.Visitor visitor) {
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
    void accept(Expr.Visitor visitor) {
      visitor.visit(this);
    }

    override
    string toString() const {
      return lexLiteralStr(literal);
    }
  }

  static class Grouping : Expr
  {
    Expr expression;
    this(Expr expression) {
      this.expression = expression;
    }
    
    override
    void accept(Expr.Visitor visitor) {
      visitor.visit(this);
    }
  }

  static class Variable : Expr {
    Token name;
    this(Token name) {
      this.name = name;
    }

    override
    void accept(Expr.Visitor visitor) {
      visitor.visit(this);
    }
  }
}

class AstPrinter : Expr.Visitor
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

  override
  void visit(Expr.Variable expr) {
    result = expr.name.lexeme;
  }

  override
  void visit(Expr.Assign expr) {
    result = expr.name.lexeme;
  }

  override
  void visit(Expr.Logical expr) {
    result = expr.operator.lexeme;
  }

  override
  void visit(Expr.Call expr) {
    result = "Function";
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