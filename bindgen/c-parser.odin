package bindgen

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"

// Global counters
anonymousStructCount := 0;
anonymousUnionCount := 0;
anonymousEnumCount := 0;

knownTypeAliases : map[string]Type;

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

is_identifier :: proc(token : string) -> bool {
    return (token[0] >= 'a' && token[0] <= 'z') ||
        (token[0] >= 'A' && token[0] <= 'Z') ||
        (token[0] == '_');
}

parse :: proc(bytes : []u8, options : ParserOptions, loc := #caller_location) -> Nodes {
    options := options;

    anonymousStructCount = 0;
    anonymousUnionCount = 0;
    anonymousEnumCount = 0;

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
        else if is_identifier(token) {
            parse_variable_or_function_declaration(&data);
        }
        else {
            print_error(&data, loc, "Unexpected token: ", token, ".");
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

parse_identifier :: proc(data : ^ParserData, loc := #caller_location) -> string {
    identifier := parse_any(data);

    if (identifier[0] < 'a' || identifier[0] > 'z') &&
        (identifier[0] < 'A' || identifier[0] > 'Z') &&
        (identifier[0] != '_') {
            print_error(data, loc, "Expected identifier but found ", identifier, ".");
        }

    return identifier;
}

// This will parse anything that look like a type:
// Builtin: char/int/float/...
// Struct-like: struct A/struct { ... }/enum E
// Function pointer: void (*f)(...)
//
// Definition permitted: If a struct-like definition is found, it will generate
// the according Node and return a corresponding type.
parse_type :: proc(data : ^ParserData, definitionPermitted := false) -> Type {
    type : Type;

    // Eat qualifiers
    token := peek_token(data);
    if token == "const" {
        eat_token(data);
        token = peek_token(data);
    }

    // Parse main type
    if token == "struct" {
        type = parse_struct_type(data, definitionPermitted);
    }
    else if token == "union" {
        type = parse_union_type(data);
    }
    else if token == "enum" {
        type = parse_enum_type(data);
    }
    else {
        // Test builtin type
        type = parse_builtin_type(data);
        if type.(BuiltinType) == BuiltinType.Unknown {
            // Test standard type
            type = parse_standard_type(data);
            if type.(StandardType) == StandardType.Unknown {
                // Basic identifier type
                identifierType : IdentifierType;
                identifierType.name = parse_identifier(data);
                type = identifierType;
            }
        }
    }

    // Eat qualifiers
    token = peek_token(data);
    if token == "const" {
        eat_token(data);
        token = peek_token(data);
    }

    // Check if pointer
    for token == "*" {
        check_and_eat_token(data, "*");
        token = peek_token(data);

        pointerType : PointerType;
        pointerType.type = new(Type);
        pointerType.type^ = type; // Copy

        type = pointerType;

        // Eat qualifiers
        if token == "const" {
            eat_token(data);
            token = peek_token(data);
        }
    }

    // ----- Function pointer type

    if token == "(" {
        check_and_eat_token(data, "(");
        check_and_eat_token(data, "*");

        functionPointerType : FunctionPointerType;
        functionPointerType.returnType = new(Type);
        functionPointerType.returnType^ = type;
        functionPointerType.name = parse_identifier(data);

        type = functionPointerType;

        check_and_eat_token(data, ")");
        parse_function_parameters(data, &functionPointerType.parameters);
    }

    return type;
}

parse_builtin_type :: proc(data : ^ParserData) -> BuiltinType {
    previousBuiltinType := BuiltinType.Unknown;
    intFound := false;
    shortFound := false;
    signedFound := false;
    unsignedFound := false;
    longCount := 0;

    for true {
        token := peek_token(data);

        if token == "void" {
            eat_token(data);
            return BuiltinType.Void;
        }
        else if token == "int" {
            eat_token(data);
            intFound = true;
            break;
        }
        else if token == "float" {
            eat_token(data);
            return BuiltinType.Float;
        }
        else if token == "double" {
            eat_token(data);
            if longCount == 0 do return BuiltinType.Double;
            else do return BuiltinType.LongDouble;
        }
        else if token == "char" {
            eat_token(data);
            if signedFound do return BuiltinType.SChar;
            else if unsignedFound do return BuiltinType.UChar;
            else do return BuiltinType.Char;
        }
        else if token == "long" do longCount += 1;
        else if token == "short" do shortFound = true;
        else if token == "unsigned" do unsignedFound = true;
        else if token == "signed" do signedFound = true;
        else if token in knownTypeAliases {
            builtinType, ok := knownTypeAliases[token].(BuiltinType);
            if ok do previousBuiltinType = builtinType;
            else do break;
        }
        else do break;

        eat_token(data);
    }

    // Adapt previous builtin type
    if previousBuiltinType == BuiltinType.ShortInt {
        shortFound = true;
    }
    else if previousBuiltinType == BuiltinType.Int {
        intFound = true;
    }
    else if previousBuiltinType == BuiltinType.LongInt {
        longCount += 1;
    }
    else if previousBuiltinType == BuiltinType.LongLongInt {
        longCount += 2;
    }
    else if previousBuiltinType == BuiltinType.UShortInt {
        unsignedFound = true;
        shortFound = true;
    }
    else if previousBuiltinType == BuiltinType.UInt {
        unsignedFound = true;
    }
    else if previousBuiltinType == BuiltinType.ULongInt {
        unsignedFound = true;
        longCount += 1;
    }
    else if previousBuiltinType == BuiltinType.ULongLongInt {
        unsignedFound = true;
        longCount += 2;
    }
    else if (previousBuiltinType != BuiltinType.Unknown) {
        return previousBuiltinType; // float, void, etc.
    }

    // Implicit and explicit int
    if intFound || shortFound || unsignedFound || signedFound || longCount > 0 {
        if unsignedFound {
            if shortFound do return BuiltinType.UShortInt;
            if longCount == 0 do return BuiltinType.UInt;
            if longCount == 1 do return BuiltinType.ULongInt;
            if longCount == 2 do return BuiltinType.ULongLongInt;
        } else {
            if shortFound do return BuiltinType.ShortInt;
            if longCount == 0 do return BuiltinType.Int;
            if longCount == 1 do return BuiltinType.LongInt;
            if longCount == 2 do return BuiltinType.LongLongInt;
        }
    }

    return BuiltinType.Unknown;
}

parse_standard_type :: proc(data : ^ParserData) -> StandardType {
    token := peek_token(data);

    if token == "int8_t" { eat_token(data); return StandardType.Int8; }
    else if token == "int16_t" { eat_token(data); return StandardType.Int16; }
    else if token == "int32_t" { eat_token(data); return StandardType.Int32; }
    else if token == "int64_t" { eat_token(data); return StandardType.Int64; }
    else if token == "uint8_t" { eat_token(data); return StandardType.UInt8; }
    else if token == "uint16_t" { eat_token(data); return StandardType.UInt16; }
    else if token == "uint32_t" { eat_token(data); return StandardType.UInt32; }
    else if token == "uint64_t" { eat_token(data); return StandardType.UInt64; }
    else if token == "size_t" { eat_token(data); return StandardType.Size; }
    else if token == "ssize_t" { eat_token(data); return StandardType.SSize; }
    else if token == "ptrdiff_t" { eat_token(data); return StandardType.PtrDiff; }
    else if token == "uintptr_t" { eat_token(data); return StandardType.UIntPtr; }
    else if token == "intptr_t" { eat_token(data); return StandardType.IntPtr; }

    return StandardType.Unknown;
}

parse_struct_type :: proc(data : ^ParserData, definitionPermitted : bool) -> IdentifierType {
    check_and_eat_token(data, "struct");

    type : IdentifierType;
    token := peek_token(data);

    if !definitionPermitted || token != "{" {
        type.name = parse_identifier(data);
        token = peek_token(data);
    } else {
        type.name = fmt.tprint("AnonymousStruct", anonymousStructCount);
        anonymousStructCount += 1;
    }

    if token == "{" {
        node := parse_struct_definition(data);
        node.name = type.name;
    } else if definitionPermitted {
        // @note Whatever happens, we create a definition of the struct,
        // as it might be used to forward declare it and then use it only with a pointer.
        // This for instance the pattern for xcb_connection_t which definition
        // is never known from user API.
        node : StructDefinitionNode;
        node.forwardDeclared = false;
        node.name = type.name;
        append(&data.nodes.structDefinitions, node);
    }

    return type;
}

parse_union_type :: proc(data : ^ParserData) -> IdentifierType {
    check_and_eat_token(data, "union");

    type : IdentifierType;
    token := peek_token(data);

    if token != "{" {
        type.name = parse_identifier(data);
        token = peek_token(data);
    } else {
        type.name = fmt.tprint("AnonymousUnion", anonymousUnionCount);
        anonymousUnionCount += 1;
    }

    if token == "{" {
        node := parse_union_definition(data);
        node.name = type.name;
    }

    return type;
}

parse_enum_type :: proc(data : ^ParserData) -> IdentifierType {
    check_and_eat_token(data, "enum");

    type : IdentifierType;
    token := peek_token(data);

    if token != "{" {
        type.name = parse_identifier(data);
        token = peek_token(data);
    } else {
        type.name = fmt.tprint("AnonymousEnum", anonymousEnumCount);
        anonymousEnumCount += 1;
    }

    if token == "{" {
        node := parse_enum_definition(data);
        node.name = type.name;
    }

    return type;
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
 * Type aliasing.
 *  typedef <sourceType> <name>;
 */
parse_typedef :: proc(data : ^ParserData) {
    check_and_eat_token(data, "typedef");

    // @note Struct-like definitions (and such)
    // are generated within type parsing.
    //
    // So that typedef struct { int foo; }* Ap; is valid.
    // Please note that generated code will create an "Anonymous struct"
    // and a type alias in such cases.

    // Parsing type
    node : TypedefNode;
    node.sourceType = parse_type(data, true);

    if sourceType, ok := node.sourceType.(FunctionPointerType); ok {
        node.name = sourceType.name;
    } else {
        node.name = parse_identifier(data);
    }

    knownTypeAliases[node.name] = node.sourceType;

    // Checking if array
    token := peek_token(data);
    if token == "[" {
        eat_token(data);
        node.dimension = cast(u64) evaluate_i64(data);
        check_and_eat_token(data, "]");
    } else {
        node.dimension = 0;
    }

    // @note Commented tool for debug
    // fmt.println("Typedef: ", node.sourceType, node.name);

    append(&data.nodes.typedefs, node);

    check_and_eat_token(data, ";");
}

parse_struct_definition :: proc(data : ^ParserData) -> ^StructDefinitionNode {
    node : StructDefinitionNode;
    node.forwardDeclared = false;
    parse_struct_or_union_members(data, &node.members);

    append(&data.nodes.structDefinitions, node);
    return &data.nodes.structDefinitions[len(data.nodes.structDefinitions) - 1];
}

parse_union_definition :: proc(data : ^ParserData) -> ^UnionDefinitionNode {
    node : UnionDefinitionNode;
    parse_struct_or_union_members(data, &node.members);

    append(&data.nodes.unionDefinitions, node);
    return &data.nodes.unionDefinitions[len(data.nodes.unionDefinitions) - 1];
}

parse_enum_definition :: proc(data : ^ParserData) -> ^EnumDefinitionNode {
    node : EnumDefinitionNode;
    parse_enum_members(data, &node.members);

    append(&data.nodes.enumDefinitions, node);
    return &data.nodes.enumDefinitions[len(data.nodes.enumDefinitions) - 1];
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
        member.type = parse_type(data, true);

        // In the case of function pointer types, the name has been parsed
        // during type inspection.
        if type, ok := member.type.(FunctionPointerType); ok {
            member.name = type.name;
        }
        else {
            // Unamed (struct or union)
            token = peek_token(data);
            if !is_identifier(token) {
                member.name = fmt.tprint("unamed", unamedCount);
                unamedCount += 1;
            }
            else {
                member.name = parse_identifier(data);
            }
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

        append(structOrUnionMembers, member);

        check_and_eat_token(data, ";");
        token = peek_token(data);
    }

    check_and_eat_token(data, "}");
}

parse_variable_or_function_declaration :: proc(data : ^ParserData) {
    type := parse_type(data, true);

    // If it's just a type, it might be a struct definition
    token := peek_token(data);
    if token == ";" {
        check_and_eat_token(data, ";");
        return;
    }

    name := parse_identifier(data);

    token = peek_token(data);
    if token == "(" {
        functionDeclarationNode := parse_function_declaration(data);
        functionDeclarationNode.returnType = type;
        functionDeclarationNode.name = name;
        return;
    }

    // Global variable declaration
    check_and_eat_token(data, ";");

    // @todo Expose global variables to generated code?
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
