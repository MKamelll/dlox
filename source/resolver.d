module resolver;

import std.range;
import std.conv;

import exprast;
import stmtast;
import interpreter;
import loxer;
import loxerr;

private enum FunctionType
{
  NONE,
  FUNCTION
}

class Resolver : Expr.Visitor, Stmt.Visitor
{
  private Interpreter interpreter;
  private bool[string][] scopes;
  private FunctionType currentFunction = FunctionType.NONE;

  this(Interpreter interpreter) {
    this.interpreter = interpreter;
  }

  override
  public void visit(Stmt.Block stmt) {
    beginScope();
    resolve(stmt.statements);
    endScope();
  }

  override
  public void visit(Expr.Variable expr) {
    if (!scopes.empty && scopes.back[expr.name.lexeme] == false) {
      Loxerr.error(expr.name, "Can't read local variable in its own intializer.");     
    }

    resolveLocal(expr, expr.name);
  }

  override
  public void visit(Expr.Assign expr) {
    resolve(expr.value);
    resolveLocal(expr, expr.name);
  }

  override
  public void visit(Stmt.Function stmt) {
    declare(stmt.name);
    define(stmt.name);

    resolveFunction(stmt, FunctionType.FUNCTION);
  }

  public void resolveFunction(Stmt.Function func, FunctionType type) {
    const FunctionType enclosingFunction = currentFunction;
    currentFunction = type;
    
    beginScope();
    foreach (param; func.params)
    {
      declare(param);
      define(param);
    }

    resolve(func.corpse);
    endScope();
    currentFunction = enclosingFunction;
  }

  override
  public void visit(Stmt.Expression stmt) {
    resolve(stmt.expression);
  }

  override
  public void visit(Stmt.If stmt) {
    resolve(stmt.condition);
    resolve(stmt.thenBranch);
    if (stmt.elseBranch !is null) {
      resolve(stmt.elseBranch);
    }
  }

  override
  public void visit(Stmt.Print stmt) {
    resolve(stmt.expression);
  }

  override
  public void visit(Stmt.Return stmt) {
    if (currentFunction == FunctionType.NONE) {
      Loxerr.error(stmt.keyword, "Can't return from top-level code.");
    }
    if (stmt.value !is null) resolve(stmt.value);
  }

  override
  public void visit(Stmt.While stmt) {
    resolve(stmt.condition);
    resolve(stmt.corpse);
  }

  override
  public void visit(Expr.Binary expr) {
    resolve(expr.left);
    resolve(expr.right);
  }

  override
  public void visit(Expr.Call expr) {
    resolve(expr.callee);

    foreach (argument; expr.arguments)
    {
      resolve(argument);  
    }
  }

  override
  public void visit(Expr.Grouping expr) {
    resolve(expr.expression);
  }

  override
  public void visit(Expr.Literal expr) { return; }

  override
  public void visit(Expr.Logical expr) {
    resolve(expr.left);
    resolve(expr.right);
  }

  override
  public void visit(Expr.Unary expr) {
    resolve(expr.right);
  }

  private void resolveLocal(Expr expr, Token name) {

    foreach_reverse (i, currScope; scopes) {
      if (name.lexeme in currScope) {
        const int distanceWalked = to!int(scopes.length) - 1 - to!int(i);
        interpreter.resolve(expr, distanceWalked);
        return;
      }
    }
  }

  public void resolve(Stmt[] statements) {
    foreach(statement; statements) {
      resolve(statement);
    }
  }

  private void resolve(Stmt stmt) {
    stmt.accept(this);
  }

  private void resolve(Expr expr) {
    expr.accept(this);
  }

  private void beginScope() {
    bool[string] newScope;
    scopes ~= newScope;
  }

  private void endScope() {
    scopes.popBack();
  }

  override
  public void visit(Stmt.Var stmt) {
    declare(stmt.name);
    if (stmt.intializer !is null) {
      resolve(stmt.intializer);
    }
    define(stmt.name);
  }

  private void declare(Token name) {
    if (scopes.empty) return;

    bool[string] newScope = scopes.back;

    if (name.lexeme in newScope) {
      Loxerr.error(name, "Already variable with this name in this scope.");
    }
    newScope = [name.lexeme : false];
  }

  private void define(Token name) {
    if (scopes.empty) return;
    scopes.back = [name.lexeme : true];
  }
}