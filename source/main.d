module main;

import std.stdio;
import std.file;
import std.conv;
import core.stdc.stdlib;

import loxer;
import exprast;
import stmtast;
import parser;
import loxerr;
import interpreter;
import resolver;

immutable string USAGE = "Usage: dlox <file>";

void runFile(string path) {
  string content = readText(path);
  run(content);
  if (hadError) exit(65);
  if (hadRuntimeError) exit(70);
}

void runPrompt() {
  while (true) {
    stdout.write("> ");
    string inputLine = stdin.readln();
    if (inputLine is null) {
      writeln("bye.");
      break;
    }
    run(inputLine);
    hadError = false;
  }
}

void run(string source) {
  auto scner = new Scanner(source);
  auto tokens = scner.scanTokens();
  auto parser = new Parser(tokens);
  auto statements = parser.parse();

  if (hadError) return;

  auto interpreter = new Interpreter();
  auto resolver = new Resolver(interpreter);
  resolver.resolve(statements);

  if (hadError) return;

  interpreter.interpret(statements);
}

void main(string[] args) {  
  string[] realArgs = args[1..$];
  if (realArgs.length > 1) {
      writeln(USAGE);
  } else if (realArgs.length == 1) {
      runFile(realArgs[0]);
  } else {
      runPrompt();
  }
}