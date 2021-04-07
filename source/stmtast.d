module stmtast;

import exprast;

abstract class Stmt {

  interface Visitor
  {
    void visit(Stmt.Expression stmt);
    void visit(Stmt.Print stmt);    
  }

  abstract void accept(Stmt.Visitor visitor);

  static class Expression : Stmt {
    Expr expression;
    this(Expr expression) {
      this.expression = expression;
    }

    override
    void accept(Stmt.Visitor visitor) {
      visitor.visit(this);
    }
  }

  static class Print : Stmt {
    Expr expression;
    this(Expr expression) {
      this.expression = expression;
    }

    override
    void accept(Stmt.Visitor visitor) {
      visitor.visit(this);
    }
  }
}