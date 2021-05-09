module parser;

import loxer;
import exprast;
import stmtast;
import std.typecons;
import loxerr;
import std.stdio;

class Parser
{
  private const Token[] tokens;
  private int current = 0;

  this(Token[] tokens) {
    this.tokens = tokens;
  }

  Stmt[] parse() {
    Stmt[] statements;
    while (!isAtEnd()) {
      statements ~= declaration();
    }
    return statements;
  }

  private Stmt declaration() {
    try {
      if (match(TokenType.FUN)) return job("function");
      if (match(TokenType.VAR)) return varDeclaration();

      return statement();
    } catch (ParseError error) {
      synchronize();
      return null;
    }
  }

  private Stmt.Function job(string kind) {
    Token name = consume(TokenType.IDENTIFIER, 
    "Expect " ~ kind ~ " name.");
    consume(TokenType.LEFT_PAREN, "Expect '(' after " ~ kind ~ " name.");
    Token[] parameters;

    if (!check(TokenType.RIGHT_PAREN)) {
      do {
        if (parameters.length >= 255) {
          error(peek(), "Can't have more than 255 parameters");
        }

        parameters ~= consume(TokenType.IDENTIFIER, "Expect parameter name.");
      } while (match(TokenType.COMMA));
    }

    consume(TokenType.RIGHT_PAREN, "Expect ')' after parameters.");

    consume(TokenType.LEFT_BRACE, "Expect '{' before " ~ kind ~ " body.");
    Stmt[] corpse = block();
    return new Stmt.Function(name, parameters, corpse);
  }

  private Stmt varDeclaration() {
    Token name = consume(TokenType.IDENTIFIER, "Expect variable name.");

    Expr intializer = null;
    if (match(TokenType.EQUAL)) {
      intializer = expression();
    }

    consume(TokenType.SEMICOLON, "Expect ';' after variable declaration.");
    return new Stmt.Var(name, intializer);
  }
  
  private Stmt statement() {
    if (match(TokenType.PRINT)) return printStatement();
    if (match(TokenType.LEFT_BRACE)) return new Stmt.Block(block());
    if (match(TokenType.IF)) return ifStatement();
    if (match(TokenType.WHILE)) return whileStatement();
    if (match(TokenType.FOR)) return forStatement();
    if (match(TokenType.RETURN)) return returnStatement();
    return expressionStatement();
  }

  private Stmt printStatement() {
    Expr value = expression();
    consume(TokenType.SEMICOLON, "Expect ';' after value.");
    return new Stmt.Print(value);
  }

  private Stmt returnStatement() {
    Token keyword = previous();
    Expr value = null;

    if (!check(TokenType.SEMICOLON)) {
      value = expression();
    }

    consume(TokenType.SEMICOLON, "Expect ';' after return statement.");
    return new Stmt.Return(keyword, value);
  }

  private Stmt[] block() {
    Stmt[] statements;

    while(!check(TokenType.RIGHT_BRACE) && !isAtEnd()) {
      statements ~= declaration();
    }

    consume(TokenType.RIGHT_BRACE, "Expect '}' after block.");

    return statements;
  }

  private Stmt forStatement() {
    consume(TokenType.LEFT_PAREN, "Expect '(' after 'for'.");

    Stmt intializer;
    if (match(TokenType.SEMICOLON)) {
      intializer = null;
    } else if (match(TokenType.VAR)) {
      intializer = varDeclaration();
    } else {
      intializer = expressionStatement();
    }

    Expr condition = null;
    if (!check(TokenType.SEMICOLON)) {
      condition = expression();
    }
    consume(TokenType.SEMICOLON, "Expect ';' after loop condition.");

    Expr increment = null;
    if (!check(TokenType.RIGHT_PAREN)) {
      increment = expression();
    }
    consume(TokenType.RIGHT_PAREN, "Expect ')' after for clauses.");

    Stmt corpse = statement();

    if (increment !is null) {
      corpse = new Stmt.Block([corpse, 
      new Stmt.Expression(increment)]);
    }

    if (condition is null) condition = new Expr.Literal(LexLiteral(true));
    corpse = new Stmt.While(condition, corpse);

    if (intializer !is null) {
      corpse = new Stmt.Block([intializer, corpse]);
    }

    return corpse;
  }

  private Stmt whileStatement() {
    consume(TokenType.LEFT_PAREN, "Expect '(' after while");
    Expr condition = expression();
    consume(TokenType.RIGHT_PAREN, "Expect ')' after condition");

    Stmt corpse = statement();

    return new Stmt.While(condition, corpse);
  }

  private Stmt ifStatement() {
    consume(TokenType.LEFT_PAREN, "Expect '(' after 'if'.");
    Expr condition = expression();
    consume(TokenType.RIGHT_PAREN, "Expect ')' after if condition.");

    Stmt thenBranch = statement();
    Stmt elseBranch = null;

    if (match(TokenType.ELSE)) {
      elseBranch = statement();
    }

    return new Stmt.If(condition, thenBranch, elseBranch);

  }

  private Stmt expressionStatement() {
    Expr expr = expression();
    consume(TokenType.SEMICOLON, "Expect ';' after expression.");
    return new Stmt.Expression(expr);
  }

  private Expr expression() {
    return assignment();
  }

  private Expr assignment() {    
    Expr expr = or();

    if (match(TokenType.EQUAL)) {
      Token equals = previous();
      Expr value = assignment();

      if (auto exprVar = cast(Expr.Variable)expr) {
        return new Expr.Assign(exprVar.name, value);
      }

      error(equals, "Invalid assignment target.");
    }

    return expr;
  }

  private Expr or() {
    Expr expr = and();

    while (match(TokenType.OR)) {
      Token operator = previous();
      Expr right = and();
      expr = new Expr.Logical(expr, operator, right);
    }

    return expr;
  }

  private Expr and() {
    Expr expr = equality();

    while (match(TokenType.AND)) {
      Token operator = previous();
      Expr right = equality();
      expr = new Expr.Logical(expr, operator, right);
    }

    return expr;
  }

  private Expr equality() {
    Expr expr = comparison();

    while (match(TokenType.BANG_EQUAL, TokenType.EQUAL_EQUAL)) {
      Token operator = previous();
      Expr right = comparison();
      expr = new Expr.Binary(expr, operator, right);
    }

    return expr;
  }

  private bool match(TokenType[] types...) {
    foreach (type; types)
    {
      if (check(type)) {
        advance();
        return true;
      }
    }
  
    return false;
  }

  private bool check(TokenType type) {
    if (isAtEnd()) return false;
    return peek().type == type;
  }

  private Token advance() {
    if (!isAtEnd()) current++;
    return previous;
  }

  private bool isAtEnd() {
    return peek().type == TokenType.EOF;
  }

  private Token peek() {
    return tokens[current];
  }

  private Token previous() {
    return tokens[current - 1];
  }

  private Expr comparison() {
    Expr expr = term();

    while (match(TokenType.GREATER, TokenType.GREATER_EQUAL,
     TokenType.LESS, TokenType.LESS_EQUAL)) {
      Token operator = previous();
      Expr right = term();
      expr = new Expr.Binary(expr, operator, right);
    }

    return expr;
  }

  private Expr term() {
    Expr expr = factor();

    while (match(TokenType.MINUS, TokenType.PLUS)) {
      Token operator = previous();
      Expr right = factor();
      expr = new Expr.Binary(expr, operator, right);
    }

    return expr;
  }

  private Expr factor() {
    Expr expr = unary();

    while (match(TokenType.SLASH, TokenType.STAR)) {
      Token operator = previous();
      Expr right = unary();
      expr = new Expr.Binary(expr, operator, right);
    }

    return expr;
  }

  private Expr unary() {
    if (match(TokenType.BANG, TokenType.MINUS)) {
      Token operator = previous();
      Expr right = unary();
      return new Expr.Unary(operator, right);
    }

    return call();
  }

  private Expr call() {
    Expr expr = primary();

    while (true) {
      if (match(TokenType.LEFT_PAREN)) {
        expr = finishCall(expr);
      } else {
        break;
      }
    }

    return expr;
  }

  private Expr finishCall(Expr callee) {
    Expr[] arguments;

    if (!check(TokenType.RIGHT_PAREN)) {
      do {
        if (arguments.length >= 255) {
          error(peek(), "Can't have more than 255 arguments.");
        }
        arguments ~= expression();
      
      } while (match(TokenType.COMMA));
    }

    Token paren = consume(TokenType.RIGHT_PAREN,
     "Expect ')' after arguments.");

    return new Expr.Call(callee, paren, arguments);
  }

  private Expr primary() {
    if (match(TokenType.FALSE)) return new Expr.Literal(LexLiteral(false));
    if (match(TokenType.TRUE)) return new Expr.Literal(LexLiteral(true));
    if (match(TokenType.NIL)) return new Expr.Literal(LexLiteral(null));

    if (match(TokenType.NUMBER, TokenType.STRING)) {
      return new Expr.Literal(previous().literal);
    }

    if (match(TokenType.IDENTIFIER)) {
      return new Expr.Variable(previous());
    }

    if (match(TokenType.LEFT_PAREN)) {
      Expr expr = expression();
      consume(TokenType.RIGHT_PAREN, "Expect ')' after expression.");
      return new Expr.Grouping(expr);
    }
    
    throw error(peek(), "Expect expression.");
  }

  private Token consume(TokenType type, string message) {
    if (check(type)) return advance();
    throw error(peek(), message);   
  }

  private ParseError error(Token token, string message) {
    Loxerr.error(token, message);    
    return new ParseError();
  }

  private void synchronize() {
    advance();

    while (!isAtEnd()) {
      if (previous().type == TokenType.SEMICOLON) return;

      switch (peek().type) {
        case TokenType.CLASS:
        case TokenType.FUN:
        case TokenType.VAR:
        case TokenType.FOR:
        case TokenType.IF:
        case TokenType.WHILE:
        case TokenType.PRINT:
        case TokenType.RETURN:
          return;
        default: break;
      }
      
      advance();
    }
  }
}