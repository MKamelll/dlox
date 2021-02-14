module main;

import std.stdio;
import std.file;
import std.conv;
import loxer;

immutable string USAGE = "Usage: dlox <file>";

void runFile(string path) {
  string content = readText(path);
  run(content);
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
  }
}

void run(string source) {
  auto scner = new Scanner(source);
  auto tokens = scner.scanTokens();
  foreach (token; tokens)
  {
    writeln(token);
  }
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