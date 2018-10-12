package bindgen

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"

CustomHandler :: proc(data : ^ParserData);
CustomExpressionHandler :: proc(data : ^ParserData) -> LiteralValue;

ParserOptions :: struct {
    ignoredTokens : []string,

    // Handlers
    customHandlers : map[string]CustomHandler,
    customExpressionHandlers : map[string]CustomExpressionHandler,
}

ParserData :: struct {
    bytes : []u8,
    bytesLength : u32,
    offset : u32,

    // References
    nodes : Nodes,
    options : ^ParserOptions,

    // Knowned values
    knownedLiterals : map[string]LiteralValue,

    // Whether we have eaten a '\n' character that has no backslash just before
    foundFullReturn : bool,
}

parse :: proc(bytes : []u8, options : ParserOptions) -> Nodes {
    data : ParserData;
    data.bytes = bytes;
    data.bytesLength = cast(u32) len(bytes);
    data.options = &options;

    for data.offset = 0; data.offset < data.bytesLength; {
        token := peek_token(&data);
        if data.offset == data.bytesLength do break;

        if token in options.customHandlers {
            options.customHandlers[token](&data);
        }
        else if token == "{" || token == "}" || token == ";" {
            eat_token(&data);
        }
        else if token == "extern" {
            check_and_eat_token(&data, "extern");
            check_and_eat_token(&data, "\"C\"");
        }
        else if token == "#" {
            parse_directive(&data);
        }
        else if token == "typedef" {
            parse_typedef(&data);
        }
        else if (token[0] >= 'a' && token[0] <= 'z') ||
                (token[0] >= 'A' && token[0] <= 'Z') {
            parse_function_declaration(&data);
        }
        else {
            fmt.print_err("[bindings] Unexpected token: ", token, "\n");
            data.offset += 1;
            return data.nodes;
        }
    }

    return data.nodes;
}

parse_any :: proc(data : ^ParserData) -> string {
    offset := peek_token_end(data);
    identifier := extract_string(data, data.offset, offset);
    data.offset = offset;
    return identifier;
}

parse_identifier :: proc(data : ^ParserData) -> string {
    return parse_any(data);
}

parse_type :: proc(data : ^ParserData) -> Type {
    kind : Type;

    startOffset := data.offset;
    eat_type_specifiers(data);
    kind.prefix = extract_string(data, startOffset, data.offset);

    startOffset = data.offset;
    eat_token(data);
    kind.main = extract_string(data, startOffset, data.offset);

    startOffset = data.offset;
    eat_type_specifiers(data);
    kind.postfix = extract_string(data, startOffset, data.offset);

    return kind;
}

/**
 * We only care about defines of some value
 */
parse_directive :: proc(data : ^ParserData) {
    check_and_eat_token(data, "#");

    token := peek_token(data);
    if token == "define" {
        parse_define(data);
    }
    // We ignore all other directives
    else {
        eat_line(data);
    }
}

parse_define :: proc(data : ^ParserData) {
    check_and_eat_token(data, "define");
    data.foundFullReturn = false;

    node : DefineNode;
    node.name = parse_identifier(data);

    // Does it look like end? It might be a #define with no expression
    if is_define_end(data) {
        node.value = 1;
        append(&data.nodes.defines, node);
        data.knownedLiterals[node.name] = node.value;
    }
    // Macros are ignored
    else if is_define_macro(data) {
        fmt.print("[bindgen] Warning: Ignoring define macro for ", node.name, "\n");
    }
    else {
        literalValue, ok := evaluate(data);
        if ok {
            node.value = literalValue;
            append(&data.nodes.defines, node);
            data.knownedLiterals[node.name] = node.value;
        }
        else {
            fmt.print("[bindgen] Warning: Ignoring define expression for ", node.name, "\n");
        }
    }

    // Evaluating the expression, we might have already eaten a full return,
    // if so, do nothing.
    if !data.foundFullReturn {
        eat_define_lines(data);
    }
}

/**
 * Inlined struct, enum or union definition aliasing:
 *  typedef (struct|enum|union) <name>? {
 *      <content>
 *  } <name>;
 *
 * Struct aliasing:
 *  typedef struct <name> <name>;
 *
 * Type alias:
 *  typedef <originalType> <name>;
 *
 * Function pointer type alias:
 * typedef <returnType> (* <name>)(<parameters>);
 */
parse_typedef :: proc(data : ^ParserData) {
    check_and_eat_token(data, "typedef");

    // Struct aliasing
    token := peek_token(data);
    if token == "struct" {
        node : StructDefinitionNode;
        check_and_eat_token(data, "struct");

        // Check if optional name
        token = peek_token(data);
        if token != "{" {
            eat_token(data); // <name>?
            token = peek_token(data);
        }

        // Check if definition
        if token == "{" {
            parse_struct_or_union_members(data, &node.members);
        }

        node.name = parse_identifier(data);
        append(&data.nodes.structDefinitions, node);
    }
    // Enum aliasing
    else if token == "enum" {
        node : EnumDefinitionNode;
        check_and_eat_token(data, "enum");

        // Check if optional name
        token = peek_token(data);
        if token != "{" {
            eat_token(data); // <name>?
        }

        // Parse definition
        parse_enum_members(data, &node.members);

        node.name = parse_identifier(data);
        append(&data.nodes.enumDefinitions, node);
    }
    // Union aliasing
    else if token == "union" {
        node : UnionDefinitionNode;
        check_and_eat_token(data, "union");

        // Check if optional name
        token = peek_token(data);
        if token != "{" {
            eat_token(data); // <name>?
        }

        // Parse definition
        parse_struct_or_union_members(data, &node.members);

        node.name = parse_identifier(data);
        append(&data.nodes.unionDefinitions, node);
    }
    // Type aliasing
    else {
        sourceType := parse_type(data);

        // Check if function pointer alising
        token = peek_token(data);
        if token == "(" {
            check_and_eat_token(data, "(");
            check_and_eat_token(data, "*");

            node : FunctionPointerTypeAliasNode;
            node.returnType = sourceType;
            node.name = parse_identifier(data);
            check_and_eat_token(data, ")");

            parse_function_parameters(data, &node.parameters);
            append(&data.nodes.functionPointerTypeAliases, node);
        } else {
            node : TypeAliasNode;
            node.sourceType = sourceType;
            node.name = parse_identifier(data);
            append(&data.nodes.typeAliases, node);
        }
    }

    check_and_eat_token(data, ";");
}

/**
 *  {
 *      <name> = <value>,
 *      <name>,
 *  }
 */
parse_enum_members :: proc(data : ^ParserData, members : ^[dynamic]EnumMember) {
    check_and_eat_token(data, "{");

    token := peek_token(data);
    for token != "}" {
        member : EnumMember;
        member.name = parse_identifier(data);
        member.hasValue = false;

        token = peek_token(data);
        if token == "=" {
            check_and_eat_token(data, "=");

            member.hasValue = true;
            member.value = evaluate_i64(data);
            data.knownedLiterals[member.name] = member.value;
            token = peek_token(data);
        }

        // Eat until end, as this might be a complex expression that we couldn't understand
        if token != "," && token != "}" {
            fmt.print("[bindgen] Warning: Parser cannot understand fully the expression of enum member ", member.name, ".\n");
            for token != "," && token != "}" {
                eat_token(data);
                token = peek_token(data);
            }
        }
        if token == "," {
            eat_token(data);
        }

        append(members, member);
    }

    check_and_eat_token(data, "}");
}

/**
 *  {
 *      <kind> <name>;
 *      <kind> <name>[<dimension>];
 *  }
 */
parse_struct_or_union_members :: proc(data : ^ParserData, structOrUnionMembers : ^[dynamic]StructOrUnionMember) {
    check_and_eat_token(data, "{");

    token := peek_token(data);
    for token != "}" {
        member : StructOrUnionMember;
        member.kind = parse_type(data);
        member.name = parse_identifier(data);

        token = peek_token(data);
        if token == "[" {
            check_and_eat_token(data, "[");
            member.dimension = cast(u32) strconv.parse_u64(parse_identifier(data));
            check_and_eat_token(data, "]");
            token = peek_token(data);
        }

        append(structOrUnionMembers, member);
        check_and_eat_token(data, ";");
        token = peek_token(data);
    }

    check_and_eat_token(data, "}");
}

parse_function_declaration :: proc(data : ^ParserData) {
    node : FunctionDeclarationNode;

    node.returnType = parse_type(data);
    node.name = parse_identifier(data);
    parse_function_parameters(data, &node.parameters);

    // @note We do not expect function definition.
    check_and_eat_token(data, ";");

    append(&data.nodes.functionDeclarations, node);
}

parse_function_parameters :: proc(data : ^ParserData, parameters : ^[dynamic]FunctionParameter) {
    check_and_eat_token(data, "(");

    token := peek_token(data);
    for token != ")" {
        parameter : FunctionParameter;
        parameter.kind = parse_type(data);

        // Check if named parameter
        token = peek_token(data);
        if token != ")" && token != "," {
            parameter.name = parse_identifier(data);
            token = peek_token(data);

            // Check if array dimension
            token = peek_token(data);
            if token == "[" {
                check_and_eat_token(data, "[");
                parameter.dimension = cast(u32) strconv.parse_u64(parse_identifier(data));
                check_and_eat_token(data, "]");
                token = peek_token(data);
            }
        }

        if token == "," {
            eat_token(data);
            token = peek_token(data);
        }

        append(parameters, parameter);
    }

    check_and_eat_token(data, ")");
}
