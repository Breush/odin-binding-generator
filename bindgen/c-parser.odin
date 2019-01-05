package bindgen

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"

// Global counters
embeddedUnionCount := 0;
embeddedStructCount := 0;

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
    embeddedUnionCount = 0;
    embeddedStructCount = 0;

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
        }
        else if token == "\"C\"" {
            check_and_eat_token(&data, "\"C\"");
        }
        else if token == "#" {
            parse_directive(&data);
        }
        else if token == "typedef" {
            parse_typedef(&data);
        }
        else if token == "struct" {
            parse_struct(&data);
            check_and_eat_token(&data, ";");
        }
        else if token == "enum" {
            parse_enum(&data);
            check_and_eat_token(&data, ";");
        }
        else if token == "union" {
            parse_union(&data);
            check_and_eat_token(&data, ";");
        }
        else if (token[0] >= 'a' && token[0] <= 'z') ||
                (token[0] >= 'A' && token[0] <= 'Z') ||
                (token[0] == '_') {
            parse_variable_or_function_declaration(&data);
        }
        else {
            fmt.print_err("[bindgen] Unexpected token: ", token, "\n");
            fmt.print_err("[bindgen] ... at ", get_line_column(&data), "\n");
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
    identifier := parse_any(data);

    if (identifier[0] < 'a' || identifier[0] > 'z') &&
        (identifier[0] < 'A' || identifier[0] > 'Z') &&
        (identifier[0] != '_') {
            fmt.print_err("[bindgen] Expected identifier but found ", identifier, "\n");
            fmt.print_err("[bindgen] ... at ", get_line_column(data), "\n");
            os.exit(1);
        }

    return identifier;
}

parse_type :: proc(data : ^ParserData) -> Type {
    // We start by parsing a type
    type : BasicType;

    startOffset := data.offset;
    implicitMain := eat_type_specifiers(data);
    type.prefix = extract_string(data, startOffset, data.offset);

    // If we get something like long long with no "int",
    // implicitMain is set
    startOffset = data.offset;
    token := peek_token(data);
    if !implicitMain || (token == "int" || token == "char" || token == "double") {
        type.main = token;
        eat_token(data);
    }

    startOffset = data.offset;
    eat_type_specifiers(data);
    type.postfix = extract_string(data, startOffset, data.offset);

    // And if it seems to continue as a function pointer type, we proceed
    token = peek_token(data);
    if token != "(" do
        return type;

    functionPointerType : FunctionPointerType;
    check_and_eat_token(data, "(");
    check_and_eat_token(data, "*");

    functionPointerType.returnType = type;
    functionPointerType.name = parse_identifier(data);
    check_and_eat_token(data, ")");

    parse_function_parameters(data, &functionPointerType.parameters);

    return functionPointerType;
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
        print_warning("Ignoring define macro for ", node.name, ".");
    }
    else {
        literalValue, ok := evaluate(data);
        if ok {
            node.value = literalValue;
            append(&data.nodes.defines, node);
            data.knownedLiterals[node.name] = node.value;
        }
        else {
            print_warning("Ignoring define expression for ", node.name, ".");
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
        node := parse_struct(data);
        node.name = parse_identifier(data);
    }
    // Enum aliasing
    else if token == "enum" {
        node := parse_enum(data);
        node.name = parse_identifier(data);
    }
    // Union aliasing
    else if token == "union" {
        node := parse_union(data);
        node.name = parse_identifier(data);
    }
    // Type aliasing
    else {
        node : TypeAliasNode;
        node.sourceType = parse_type(data);

        // In the case of function pointer types, the name has been parsed
        // during type inspection.
        if sourceType, ok := node.sourceType.(FunctionPointerType); ok {
            node.name = sourceType.name;
        }
        else {
            node.name = parse_identifier(data);
        }
        append(&data.nodes.typeAliases, node);
    }

    check_and_eat_token(data, ";");
}

parse_struct :: proc(data : ^ParserData) -> ^StructDefinitionNode {
    check_and_eat_token(data, "struct");

    node : StructDefinitionNode;
    node.forwardDeclared = false;

    // Check if optional name
    token := peek_token(data);
    if token != "{" {
        node.name = parse_identifier(data);
        token = peek_token(data);
    }

    // Check if definition
    if token == "{" {
        parse_struct_or_union_members(data, &node.members);
        node.forwardDeclared = true;
    }

    append(&data.nodes.structDefinitions, node);

    return &data.nodes.structDefinitions[len(data.nodes.structDefinitions) - 1];
}


parse_enum :: proc(data : ^ParserData) -> ^EnumDefinitionNode {
    check_and_eat_token(data, "enum");

    node : EnumDefinitionNode;

    // Check if optional name
    token := peek_token(data);
    if token != "{" {
        eat_token(data); // <name>?
    }

    // Check if definition
    if token == "{" {
        parse_enum_members(data, &node.members);
    }

    append(&data.nodes.enumDefinitions, node);

    return &data.nodes.enumDefinitions[len(data.nodes.enumDefinitions) - 1];
}

parse_union :: proc(data : ^ParserData) -> ^UnionDefinitionNode {
    check_and_eat_token(data, "union");

    node : UnionDefinitionNode;

    // Check if optional name
    token := peek_token(data);
    if token != "{" {
        node.name = parse_identifier(data);
        token = peek_token(data);
    }

    // Check if definition
    if token == "{" {
        parse_struct_or_union_members(data, &node.members);
    }

    append(&data.nodes.unionDefinitions, node);

    return &data.nodes.unionDefinitions[len(data.nodes.unionDefinitions) - 1];
}

/**
 *  {
 *      <name> = <value>,
 *      <name>,
 *  }
 */
parse_enum_members :: proc(data : ^ParserData, members : ^[dynamic]EnumMember) {
    check_and_eat_token(data, "{");

    nextMemberValue : i64 = 0;
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
            nextMemberValue = member.value;
            token = peek_token(data);
        } else {
            member.value = nextMemberValue;
        }

        data.knownedLiterals[member.name] = member.value;
        nextMemberValue += 1;

        // Eat until end, as this might be a complex expression that we couldn't understand
        if token != "," && token != "}" {
            print_warning("Parser cannot understand fully the expression of enum member ", member.name, ".");
            for token != "," && token != "}" {
                eat_token(data);
                token = peek_token(data);
            }
        }
        if token == "," {
            check_and_eat_token(data, ",");
            token = peek_token(data);
        }

        append(members, member);
    }

    check_and_eat_token(data, "}");
}

/**
 *  {
 *      <type> <name>;
 *      <type> <name>[<dimension>];
 *  }
 */
parse_struct_or_union_members :: proc(data : ^ParserData, structOrUnionMembers : ^[dynamic]StructOrUnionMember) {
    check_and_eat_token(data, "{");

    // To ensure unique id
    unamedCount := 0;

    token := peek_token(data);
    for token != "}" {
        member : StructOrUnionMember;

        // Checking if embedding
        embeddedStructOrUnion := false;
        if token == "union" || token == "struct" {
            startOffset := data.offset;
            eat_token(data);

            token = peek_token(data);
            if token != "{" {
                eat_token(data); // Identifier
                token = peek_token(data);
            }

            embeddedStructOrUnion = (token == "{");
            data.offset = startOffset;
            token = peek_token(data);
        }

        // Embedded union
        if embeddedStructOrUnion && token == "union" {
            unionNode := parse_union(data);
            unionNode.name = fmt.tprint("EmbeddedUnion", embeddedUnionCount);
            embeddedUnionCount += 1;


            // Union might be named
            token = peek_token(data);
            if token != "," && token != ";" && token != "}" {
                member.name = parse_identifier(data);
            }
            else {
                member.name = fmt.tprint("unamed", unamedCount);
                unamedCount += 1;
            }

            type : BasicType;
            type.main = unionNode.name;
            member.type = type;
        }
        // Embedded struct
        else if embeddedStructOrUnion && token == "struct" {
            structNode := parse_struct(data);
            structNode.name = fmt.tprint("EmbeddedStruct", embeddedStructCount);
            embeddedStructCount += 1;

            member.name = parse_identifier(data);

            type : BasicType;
            type.main = structNode.name;
            member.type = type;
        }
        else {
            member.type = parse_type(data);

            // In the case of function pointer types, the name has been parsed
            // during type inspection.
            if type, ok := member.type.(FunctionPointerType); ok {
                member.name = type.name;
            }
            else {
                member.name = parse_identifier(data);
            }

            token = peek_token(data);
            for token == "[" {
                check_and_eat_token(data, "[");
                dimension := evaluate_i64(data);
                append(&member.dimensions, cast(u64) dimension);
                check_and_eat_token(data, "]");
                token = peek_token(data);
            }

            if token == ":" {
                check_and_eat_token(data, ":");
                print_warning("Found bitfield in struct, which is not handled correctly.");
                evaluate_i64(data);
                token = peek_token(data);
            }
        }

        append(structOrUnionMembers, member);

        check_and_eat_token(data, ";");
        token = peek_token(data);
    }

    check_and_eat_token(data, "}");
}

parse_variable_or_function_declaration :: proc(data : ^ParserData) {
    type := parse_type(data);
    name := parse_identifier(data);

    token := peek_token(data);
    if token == "(" {
        functionDeclarationNode := parse_function_declaration(data);
        functionDeclarationNode.returnType = type;
        functionDeclarationNode.name = name;
        return;
    }

    // Global variable declaration
    check_and_eat_token(data, ";");

    // @todo Expose global variables?
}

parse_function_declaration :: proc(data : ^ParserData) -> ^FunctionDeclarationNode {
    node : FunctionDeclarationNode;

    parse_function_parameters(data, &node.parameters);

    // Function definition? Ignore it.
    token := peek_token(data);
    if token == "{" {
        bracesCount := 1;
        for true {
            data.offset += 1;
            if data.bytes[data.offset] == '{' do bracesCount += 1;
            else if data.bytes[data.offset] == '}' do bracesCount -= 1;
            if bracesCount == 0 do break;
        }
        data.offset += 1;
    }
    // Function declaration
    else {
        check_and_eat_token(data, ";");
    }

    append(&data.nodes.functionDeclarations, node);
    return &data.nodes.functionDeclarations[len(data.nodes.functionDeclarations) - 1];
}

parse_function_parameters :: proc(data : ^ParserData, parameters : ^[dynamic]FunctionParameter) {
    check_and_eat_token(data, "(");

    token := peek_token(data);
    for token != ")" {
        parameter : FunctionParameter;

        token = peek_token(data);
        if token == "." {
            print_warning("A function accepts variadic arguments, this is currently not handled within generated code.");

            check_and_eat_token(data, ".");
            check_and_eat_token(data, ".");
            check_and_eat_token(data, ".");
            break;
        } else {
            parameter.type = parse_type(data);
        }

        // Check if named parameter
        token = peek_token(data);
        if token != ")" && token != "," {
            parameter.name = parse_identifier(data);
            token = peek_token(data);

            // Check if array dimension
            token = peek_token(data);
            for token == "[" {
                check_and_eat_token(data, "[");
                token = peek_token(data);
                if token != "]" {
                    dimension := evaluate_i64(data);
                    append(&parameter.dimensions, cast(u64) dimension);
                }
                // @fixme Currently ignoring empty [], but shouldn't
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
