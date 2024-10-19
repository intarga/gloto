import gleam/io
import gleam/set
import nibble/lexer

// import nibble.{do, return}

// // sample to parse:
// message Point {
//   required int32 x = 1;
//   required int32 y = 2;
//   // optional string label = 3;
// }

type Token {
  Message
  LeftCurly
  RightCurly
  FieldSpec
  Equals
  Semicolon
  Num(Int)
  Comment(String)
  PascalIdentifier(String)
  SnakeIdentifier(String)
}

pub fn main() -> Nil {
  let sample_proto =
    "
// sample to parse:
message Point {
  required int32 x = 1;
  required int32 y = 2;
  // optional string label = 3;
}"

  let lexer =
    lexer.simple([
      lexer.keyword("message", "\\W", Message),
      lexer.token("{", LeftCurly),
      lexer.token("}", RightCurly),
      lexer.keyword("required", "\\W", FieldSpec),
      lexer.token("=", Equals),
      lexer.token(";", Semicolon),
      lexer.int(Num),
      lexer.comment("//", Comment),
      lexer.identifier("[A-Z]", "[a-zA-Z0-9_]", set.new(), PascalIdentifier),
      lexer.variable(set.new(), SnakeIdentifier),
      lexer.whitespace(Nil) |> lexer.ignore,
    ])

  let assert Ok(tokens) = lexer.run(sample_proto, lexer)

  io.debug(tokens)

  Nil
}
