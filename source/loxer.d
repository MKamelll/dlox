module loxer;

import std.variant;
import std.format;
import std.conv;
import std.typecons;
import std.stdio;
import loxerr;

enum TokenType
{
	
  // Single-character tokens.
  LEFT_PAREN, RIGHT_PAREN, LEFT_BRACE, RIGHT_BRACE,
  COMMA, DOT, MINUS, PLUS, SEMICOLON, SLASH, STAR,

  // One or two character tokens.
  BANG, BANG_EQUAL,
  EQUAL, EQUAL_EQUAL,
  GREATER, GREATER_EQUAL,
  LESS, LESS_EQUAL,

  // LexLiterals.
  IDENTIFIER, STRING, NUMBER,

  // Keywords.
  AND, CLASS, ELSE, FALSE, FUN, FOR, IF, NIL, OR,
  PRINT, RETURN, SUPER, THIS, TRUE, VAR, WHILE,

  EOF
}

alias LexLiteral = Algebraic!(int, string, double, typeof(null));
string lexLiteralStr(LexLiteral literal) {
  return literal.toString();
}

struct Token
{
  TokenType type;
  string lexeme;
  LexLiteral literal;
  int line;

  string toString() const {
    return "Token(" ~ to!string(type) ~ ", " ~ 
    lexeme ~ ", " ~ lexLiteralStr(literal) ~ ")";
  }
}

class Scanner
{
  private string source;
  private Token[] tokens;
  private int start;
  private int current;
  private int line;
  private immutable TokenType[string] keywords;
  
  this(string source) {
    this.source = source;
    this.start = 0;
    this.current = 0;
    this.line = 1;
    this.keywords = [
      "and"   :TokenType.AND,
      "class" :TokenType.CLASS,
      "else"  :TokenType.ELSE,
      "false" :TokenType.FALSE,
      "for"   :TokenType.FOR,
      "fun"   :TokenType.FUN,
      "if"    :TokenType.IF,
      "nil"   :TokenType.NIL,
      "or"    :TokenType.OR,
      "print" :TokenType.PRINT,
      "return":TokenType.RETURN,
      "super" :TokenType.SUPER,
      "this"  :TokenType.THIS,
      "true"  :TokenType.TRUE,
      "var"   :TokenType.VAR,
      "while" :TokenType.WHILE,
    ];
  }

  Token[] scanTokens() {
    while(!isAtEnd()) {
      start = current;
      scanToken();
    }
    tokens ~= Token(TokenType.EOF, "\"\"",
     LexLiteral(null), line);
    return tokens;
  }

  private bool isAtEnd() {
    return current >= source.length;
  }

  private void scanToken() {
    char c = advance();
    switch(c) {
      case '(':
        addToken(TokenType.LEFT_PAREN); break;
      case ')':
        addToken(TokenType.RIGHT_PAREN); break;
      case '{': 
        addToken(TokenType.LEFT_BRACE); break;
      case '}': 
        addToken(TokenType.RIGHT_BRACE); break;
      case ',': 
        addToken(TokenType.COMMA); break;
      case '.':
        addToken(TokenType.DOT); break;
      case '-':
        addToken(TokenType.MINUS); break;
      case '+':
        addToken(TokenType.PLUS); break;
      case ';':
        addToken(TokenType.SEMICOLON); break;
      case '*':
        addToken(TokenType.STAR); break;
      case '!':
        addToken(match('=') ? TokenType.EQUAL_EQUAL 
        : TokenType.BANG);
        break;
      case '=': 
        addToken(match('=') ? TokenType.EQUAL_EQUAL
        : TokenType.EQUAL);
        break;
      case '<':
        addToken(match('=') ? TokenType.LESS_EQUAL
        : TokenType.LESS);
        break;
      case '>':
        addToken(match('=') ? TokenType.GREATER_EQUAL 
        : TokenType.GREATER);
        break;
      case '/':
        if(match('/')) {
          while(peek() != '\n' && !isAtEnd()) advance();
        } else {
          addToken(TokenType.SLASH);
        } 
        break;
      case ' ', '\t', '\r':
        break;
      case '\n':
        line++;
        break;
      case '"':
        aString();
        break;
      default:
        if (isDigit(c)) {
          aNumber();
        } else if (isAlpha(c)) {
          anIdentifier();
        } else {
          Loxerr.error(line, "Unexpected character."); break;
        }
    }
  }

  private char advance() {
    current++;
    return source[current - 1];
  }

  private void addToken(TokenType type) {
    addToken(type, LexLiteral(null));
  }

  private void addToken(TokenType type, LexLiteral literal) {
    string text = source[start..current];
    tokens ~= Token(type, text, literal, line);
  }

  private bool match(char expected) {
    if (isAtEnd()) return false;
    if (source[current] != expected) return false;
    current++;
    return true;
  }

  private char peek() {
    if (isAtEnd()) return '\0';
    return source[current];
  }

  private void aString() {
    while (peek() != '"' && !isAtEnd()) {
      if (peek() == '\n') line++;
      advance();
    }

    if (isAtEnd()) {
      Loxerr.error(line, "Unterminated string.");
    }

    // for the closing "
    advance();

    // trimming quotes
    string value = source[(start + 1)..(current - 1)];
    addToken(TokenType.STRING, LexLiteral(value));
  }

  private bool isDigit(char c) {
    return c >= '0' && c <= '9';
  }

  private void aNumber() {
    while (isDigit(peek())) advance();
    if (peek() == '.' && isDigit(peekNext())) {
      advance();
      while (isDigit(peek())) advance();     
    }
    addToken(TokenType.NUMBER, 
    LexLiteral(to!double(source[start..current])));
  }

  private char peekNext() {
    if (current + 1 >= source.length) return '\0';
    return source[current + 1];
  }

  private bool isAlpha(char c) {
    return (c >= 'a' && c <= 'z') ||
           (c >= 'A' && c <= 'Z') ||
           (c == '_');
  }

  private void anIdentifier() {
    while (isAlphaNumeric(peek())) advance();

    string text = source[start..current - 1];
    TokenType type = text in keywords ? keywords[text]
    : TokenType.IDENTIFIER;
    
    addToken(type);
  }

  private bool isAlphaNumeric(char c) {
    return isAlpha(c) || isDigit(c);
  }
}