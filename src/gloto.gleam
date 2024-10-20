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
// sample to parse:
message Point {
  required int32 x = 1;
  required int32 y = 2;
  // optional string label = 3;
}"

  let lexer =
    lexer.simple([
      lexer.keyword("message", "\\W", MessageKeyword),
      lexer.token("{", LeftCurly),
      lexer.token("}", RightCurly),
      lexer.keyword("required", "\\W", FieldSpec),
      lexer.token("=", Equals),
      lexer.token(";", Semicolon),
      lexer.int(Num),
      lexer.identifier("[A-Z]", "[a-zA-Z0-9_]", set.new(), PascalIdentifier),
      lexer.variable(set.new(), SnakeIdentifier),
      lexer.comment("//", Comment) |> lexer.ignore,
      lexer.whitespace(Nil) |> lexer.ignore,
    ])

  let parse_pascal_identifier = {
    use tok <- nibble.take_map("Expected PascalCase identifier")
    case tok {
      PascalIdentifier(str) -> Some(str)
      _ -> None
    }
  }

  let parse_snake_identifier = {
    use tok <- nibble.take_map("Expected snake_case identifier")
    case tok {
      SnakeIdentifier(str) -> Some(str)
      _ -> None
    }
  }

  let parse_num = {
    use tok <- nibble.take_map("Expected number")
    case tok {
      Num(num) -> Some(num)
      _ -> None
    }
  }

  let parse_field = {
    use _ <- do(nibble.token(FieldSpec))
    use type_ <- do(parse_snake_identifier)
    use name <- do(parse_snake_identifier)
    use _ <- do(nibble.token(Equals))
    use tag <- do(parse_num)
    use _ <- do(nibble.token(Semicolon))

    return(Field(Some(Required), type_:, name:, tag:))
  }

  let parser = {
    use _ <- do(nibble.token(MessageKeyword))
    use message_name <- do(parse_pascal_identifier)
    use _ <- do(nibble.token(LeftCurly))
    // TODO: should this be many1?
    use fields <- do(nibble.many(parse_field))
    use _ <- do(nibble.token(RightCurly))

    return(Message(message_name, fields))
  }

  let assert Ok(tokens) = lexer.run(sample_proto, lexer)
  io.debug(tokens)

  let assert Ok(message) = nibble.run(tokens, parser)
  io.debug(message)

  Nil
}
