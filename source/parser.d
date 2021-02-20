module parser;

import loxer;
import loxast;
import std.typecons;

class ParseError : Exception
{
  this(string msg = "", string file = __FILE__,
   size_t line = __LINE__,
    Throwable nextInChain = null) pure nothrow @nogc @safe
  {
    super(msg, file, line, nextInChain);
  }
}

class Parser
{
  private const Token[] tokens;
  private int current = 0;

  this(Token[] tokens) {
    this.tokens = tokens;
  }

  Nullable!Expr parse() {
    Nullable!Expr result;
    try {
      result = expression().nullable;
    } catch (ParseError error) {}
    return result;
  }

  private Expr expression() {
    return equality();
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

    return primary();
  }

  private Expr primary() {
    if (match(TokenType.FALSE)) return new Expr.Literal(LexLiteral(false));
    if (match(TokenType.TRUE)) return new Expr.Literal(LexLiteral(true));
    if (match(TokenType.NIL)) return new Expr.Literal(LexLiteral(null));

    if (match(TokenType.NUMBER, TokenType.STRING)) {
      return new Expr.Literal(previous().literal);
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
    import loxerr : Loxerr;
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