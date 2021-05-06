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
    void visit(Stmt.If stmt);
    void visit(Stmt.While stmt);
  }

  abstract void accept(Stmt.Visitor visitor);

  static class While : Stmt {
    Expr condition;
    Stmt corpse; // body is a D keyword

    this(Expr condition, Stmt corpse) {
      this.condition = condition;
      this.corpse = corpse;
    }

    override
    void accept(Stmt.Visitor visitor) {
      visitor.visit(this);
    }
  }

  static class If : Stmt {
    Expr condition;
    Stmt thenBranch;
    Stmt elseBranch;

    this(Expr condition, Stmt thenBranch, Stmt elseBranch) {
      this.condition = condition;
      this.thenBranch = thenBranch;
      this.elseBranch = elseBranch;
    }

    override
    void accept(Stmt.Visitor visitor) {
      visitor.visit(this);
    }
  }

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