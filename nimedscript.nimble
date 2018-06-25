# Package

version       = "0.1.0"
author        = "hlaaftana"
description   = "FL Studio EdisonScript JS wrapper "
license       = "MIT"
srcDir        = "src"
skipDirs      = @["tests"]

# Dependencies

requires "nim >= 0.18.0"

task docs, "Build documentation":
  exec "nim doc -o:docs/nimedscript.html src/nimedscript.nim"

import ospaths, strformat, strutils

proc transform(text: string): string =
  # i would have done all of this better with regex or pegs or whatever but this'll have to do unless we hit a barrier
  result = text
  result = result.replace("if (typeof ", "//") # edscript doesn't like typeof undefined checking
  result = result.replace("base:", "\"base\":") # it also doesn't like "base" as an identifier
  result = result.replace("break ", "break; ") # it also doesn't like labeled break/continue

task buildTests, "Compiles tests to javascript":
  for test in listFiles("tests"):
    let split = splitFile(test)
    if split.ext == ".nim":
      let path = "bin/" & split.name & ".edscript"
      exec "nim js --gc:none -d:release -o:" & path & " " & test
      writeFile(path, &"""script "{split.name}" language "javascript";
{transform(readFile(path))}""")