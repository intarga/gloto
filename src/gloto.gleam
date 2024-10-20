import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/set
import nibble.{do, return}
import nibble/lexer

type FieldSpec {
  Required
}

type Field {
  Field(field_spec: Option(FieldSpec), type_: String, name: String, tag: Int)
}

type Message {
  Message(name: String, fields: List(Field))
}

type Token {
  MessageKeyword
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
message Point {
  required int32 x = 1;
  required int32 y = 2;
}"
  // TODO: discard comments so we can put these back in
  // // sample to parse:
  //   // optional string label = 3;

  let lexer =
    lexer.simple([
      lexer.keyword("message", "\\W", MessageKeyword),
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

  let parse_pascal_identifier = {
    use tok <- nibble.take_map("Expected Pascal-case identifier")
    case tok {
      PascalIdentifier(str) -> Some(str)
      _ -> None
    }
  }

  let parse_field = {
    use toks <- nibble.then(nibble.take_until(fn(tok) { tok == Semicolon }))

    case toks {
      [
        FieldSpec,
        SnakeIdentifier(type_),
        SnakeIdentifier(name),
        Equals,
        Num(tag),
      ] -> nibble.return(Field(Some(Required), type_:, name:, tag:))
      _ -> nibble.fail("Expected field")
    }
  }

  // let parse_fields = {
  //   todo
  // }

  let parser = {
    use _ <- do(nibble.token(MessageKeyword))
    use message_name <- do(parse_pascal_identifier)
    use _ <- do(nibble.token(LeftCurly))
    // use fields <- do(parse_fields)
    use field1 <- do(parse_field)
    use _ <- do(nibble.token(Semicolon))
    use field2 <- do(parse_field)
    use _ <- do(nibble.token(Semicolon))
    use _ <- do(nibble.token(RightCurly))

    return(Message(message_name, [field1, field2]))
  }

  let assert Ok(tokens) = lexer.run(sample_proto, lexer)
  io.debug(tokens)

  let assert Ok(message) = nibble.run(tokens, parser)
  io.debug(message)

  Nil
}
