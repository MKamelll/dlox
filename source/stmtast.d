module stmtast;

import exprast;
import loxer;

abstract class Stmt {

  interface Visitor
  {
    void visit(Stmt.Expression stmt);
    void visit(Stmt.Print stmt);
    void visit(Stmt.Var stmt);
    void visit(Stmt.Block stmt);
  }

  abstract void accept(Stmt.Visitor visitor);

  static class Block : Stmt {
    Stmt[] statements;
    this(Stmt[] statements) {
      this.statements = statements;
    }

    override
    void accept(Stmt.Visitor visitor) {
      visitor.visit(this);
    }
  }

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

  static class Var : Stmt {
    Token name;
    Expr intializer;
    this(Token name, Expr intializer) {
      this.name = name;
      this.intializer = intializer;
    }

    override
    void accept(Stmt.Visitor visitor) {
      visitor.visit(this);
    }
  }
}