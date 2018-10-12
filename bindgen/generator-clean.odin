package bindgen

import "core:fmt"

// Prevent keywords clashes and other tricky cases
clean_identifier :: proc(name : string) -> string {
    if name == "" {
        return name;
    }

    // Starting with _? Try removing that.
    for true {
        if name[0] == '_' {
            name = name[1:];
        }
        else {
            break;
        }
    }

    // Number
    if name[0] >= '0' && name[0] <= '9' {
        return fmt.tprint("_", name);
    }

    // Keywords clash
    if name == "type" || name == "map" {
        return fmt.tprint("_", name);
    }

    return name;
}

clean_variable_name :: proc(name : string, options : ^GeneratorOptions) -> string {
    name = change_case(name, options.variableCase);
    return clean_identifier(name);
}

clean_pseudo_type_name :: proc(structName : string, options : ^GeneratorOptions) -> string {
    structName = remove_postfixes(structName, options.pseudoTypePostfixes, options.pseudoTypeTransparentPostfixes);
    structName = remove_prefixes(structName, options.pseudoTypePrefixes, options.pseudoTypeTransparentPrefixes);
    structName = change_case(structName, options.pseudoTypeCase);
    return structName;
}

// Clean up the enum name so that it can be used to remove the prefix from enum values.
clean_enum_name_for_prefix_removal :: proc(enumName : string, options : ^GeneratorOptions) -> (string, [dynamic]string) {
    if !options.enumValueNameRemove {
        return enumName, nil;
    }

    // Remove postfix and use same case convention as the enum values
    removedPostfixes : [dynamic]string;
    enumName, removedPostfixes = remove_postfixes_with_removed(enumName, options.enumValueNameRemovePostfixes);
    enumName = change_case(enumName, options.enumValueCase);
    return enumName, removedPostfixes;
}

clean_enum_value_name :: proc(valueName : string, enumName : string, postfixes : []string, options : ^GeneratorOptions) -> string {
    valueName = remove_prefixes(valueName, options.enumValuePrefixes, options.enumValueTransparentPrefixes);
    valueName = remove_postfixes(valueName, postfixes, options.enumValueTransparentPostfixes);
    valueName = change_case(valueName, options.enumValueCase);

    if options.enumValueNameRemove {
        valueName = remove_prefixes(valueName, []string{enumName});
    }

    return clean_identifier(valueName);
}

clean_function_name :: proc(functionName : string, options : ^GeneratorOptions) -> string {
    functionName = remove_prefixes(functionName, options.functionPrefixes, options.functionTransparentPrefixes);
    functionName = remove_postfixes(functionName, options.definePostfixes, options.defineTransparentPostfixes);
    functionName = change_case(functionName, options.functionCase);
    return functionName;
}

clean_define_name :: proc(defineName : string, options : ^GeneratorOptions) -> string {
    defineName = remove_prefixes(defineName, options.definePrefixes, options.defineTransparentPrefixes);
    defineName = remove_postfixes(defineName, options.definePostfixes, options.defineTransparentPostfixes);
    defineName = change_case(defineName, options.defineCase);
    return defineName;
}

// Convert to Odin's types
clean_type :: proc(kind : Type, options : ^GeneratorOptions) -> string {
    // If it matches the prefix, then it might be a struct.
    main := kind.main;

    if main == "int" { main = "i32"; }
    else if main == "char" { main = "u8"; }
    else if main == "int8_t" { main = "i8"; }
    else if main == "uint8_t" { main = "u8"; }
    else if main == "int16_t" { main = "i16"; }
    else if main == "uint16_t" { main = "u16"; }
    else if main == "int32_t" { main = "i32"; }
    else if main == "uint32_t" { main = "u32"; }
    else if main == "int64_t" { main = "i64"; }
    else if main == "uint64_t" { main = "u64"; }
    else if main == "size_t" { main = "u64"; }
    else if main == "float" { main = "f32"; }
    else if main == "double" { main = "f64"; }
    else if main == "void" { main = ""; }
    else {
        main = clean_pseudo_type_name(main, options);
    }

    // Check pointerness
    odinPrefix := "";
    for character in kind.postfix {
        if character == '*' {
            if len(main) == 0 {
                main = "rawptr";
            }
            else if main == "u8" {
                main = "cstring";
            }
            else {
                odinPrefix = fmt.tprint("^", odinPrefix);
            }
        }
    }

    // Check unsigness
    // @fixme If unsigned and int -> u32

    return fmt.tprint(odinPrefix, main);
}
