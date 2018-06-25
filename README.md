# NimEdScript

A wrapper around EdisonScript/JavaScript in FL Studio for Nim.

It's important to note that EdisonScript's JS implementation is virtually lower than JavaScript 1.0, it lacks an enormous amount of features from the JavaScript language as it's mostly supposed to be a scripting language based around Pascal. The Nim JS output needs some transforming to get right, and until I've done something for that it's best to clone this repo, run nimble buildTests then copy the output in the bin folder to the FL studio scripts folder.

List of things that do not work in edscript:

* Math.trunc therefore vanilla Nim `mod` (hangs)
* The expression `typeof Int8Array` if Int8Array isn't defined, breaks nim default header even if unused
* Object default constructors like `var result = {a: 0, b: 0, c: 0, d: 0}; result = otherVar;` (slows it down a LOT, noinit doesn't change anything, use emit/importc/nodecl)
* Break/continue with labels, however labels and do/while loops are allowed
* Switch statement
* Any subscript access of any kind
* The identifier "base" whether variable or object key

This needs the following post-codegen transforms:

* Add `script "Script name" language "javascript"` to top of file
* 'base:' -> '"base":', if theres a var named base tough luck
* remove/comment out/simplify default nim primitive array header
* simply remove labels from labeled break/continue statements, this might break some block contraptions

This makes the following impossible:

* Anything that generates `nimCopy`
  - Assigning object types to variables
* Anything that generates nim string/seq behaviour
  - Use cstring and JS arrays

Also to note, 