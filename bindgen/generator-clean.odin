package bindgen

import "core:fmt"

// Prevent keywords clashes and other tricky cases
clean_identifier :: proc(name : string) -> string {
    name := name;

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
    else if name == "map" || name == "proc" || name == "opaque" || name == "in" {
        return fmt.tprint("_", name);
    }

    return name;
}

clean_variable_name :: proc(name : string, options : ^GeneratorOptions) -> string {
    name := name;
    name = change_case(name, options.variableCase);
    return clean_identifier(name);
}

clean_pseudo_type_name :: proc(structName : string, options : ^GeneratorOptions) -> string {
    structName := structName;
    structName = remove_postfixes(structName, options.pseudoTypePostfixes, options.pseudoTypeTransparentPostfixes);
    structName = remove_prefixes(structName, options.pseudoTypePrefixes, options.pseudoTypeTransparentPrefixes);
    structName = change_case(structName, options.pseudoTypeCase);
    return structName;
}

// Clean up the enum name so that it can be used to remove the prefix from enum values.
clean_enum_name_for_prefix_removal :: proc(enumName : string, options : ^GeneratorOptions) -> (string, [dynamic]string) {
    enumName := enumName;

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
    valueName := valueName;

    valueName = remove_prefixes(valueName, options.enumValuePrefixes, options.enumValueTransparentPrefixes);
    valueName = remove_postfixes(valueName, postfixes, options.enumValueTransparentPostfixes);
    valueName = change_case(valueName, options.enumValueCase);

    if options.enumValueNameRemove {
        valueName = remove_prefixes(valueName, []string{enumName});
    }

    return clean_identifier(valueName);
}

clean_function_name :: proc(functionName : string, options : ^GeneratorOptions) -> string {
    functionName := functionName;
    functionName = remove_prefixes(functionName, options.functionPrefixes, options.functionTransparentPrefixes);
    functionName = remove_postfixes(functionName, options.definePostfixes, options.defineTransparentPostfixes);
    functionName = change_case(functionName, options.functionCase);
    return functionName;
}

clean_define_name :: proc(defineName : string, options : ^GeneratorOptions) -> string {
    defineName := defineName;
    defineName = remove_prefixes(defineName, options.definePrefixes, options.defineTransparentPrefixes);
    defineName = remove_postfixes(defineName, options.definePostfixes, options.defineTransparentPostfixes);
    defineName = change_case(defineName, options.defineCase);
    return defineName;
}

// Convert to Odin's types
clean_type :: proc(type : Type, options : ^GeneratorOptions, baseTab : string = "") -> string {
    if _type, ok := type.(BuiltinType); ok {
        if _type == BuiltinType.Void do return "";
        else if _type == BuiltinType.Int do return "_c.int";
        else if _type == BuiltinType.UInt do return "_c.uint";
        else if _type == BuiltinType.LongInt do return "_c.long";
        else if _type == BuiltinType.ULongInt do return "_c.ulong";
        else if _type == BuiltinType.LongLongInt do return "_c.longlong";
        else if _type == BuiltinType.ULongLongInt do return "_c.ulonglong";
        else if _type == BuiltinType.ShortInt do return "_c.short";
        else if _type == BuiltinType.UShortInt do return "_c.ushort";
        else if _type == BuiltinType.Char do return "_c.char";
        else if _type == BuiltinType.SChar do return "_c.schar";
        else if _type == BuiltinType.UChar do return "_c.uchar";
        else if _type == BuiltinType.Float do return "_c.float";
        else if _type == BuiltinType.Double do return "_c.double";
        else if _type == BuiltinType.LongDouble {
            print_warning("Found long double which is currently not supported. Fallback to double in generated code.");
            return "_c.double";
        }
    }
    else if _type, ok := type.(StandardType); ok {
        if _type == StandardType.Int8 do return "i8";
        else if _type == StandardType.Int16 do return "i16";
        else if _type == StandardType.Int32 do return "i32";
        else if _type == StandardType.Int64 do return "i64";
        else if _type == StandardType.UInt8 do return "u8";
        else if _type == StandardType.UInt16 do return "u16";
        else if _type == StandardType.UInt32 do return "u32";
        else if _type == StandardType.UInt64 do return "u64";
        else if _type == StandardType.Size do return "_c.size_t";
        else if _type == StandardType.SSize do return "_c.ssize_t";
        else if _type == StandardType.PtrDiff do return "_c.ptrdiff_t";
        else if _type == StandardType.UIntPtr do return "_c.uintptr_t";
        else if _type == StandardType.IntPtr do return "_c.intptr_t";
    }
    else if _type, ok := type.(PointerType); ok {
        if __type, ok := _type.type.(BuiltinType); ok {
            if __type == BuiltinType.Void do return "rawptr";
            else if __type == BuiltinType.Char do return "cstring";
        }
        name := clean_type(_type.type^, options, baseTab);
        return fmt.tprint("^", name);
    }
    else if _type, ok := type.(IdentifierType); ok {
        return clean_pseudo_type_name(_type.name, options);
    }
    else if _type, ok := type.(FunctionPointerType); ok {
        output := "#type proc(";
        parameters := clean_function_parameters(_type.parameters, options, baseTab);
        output = fmt.tprint(output, parameters, ")");
        // @fixme And return value!?
        return output;
    }

    return "<niy>";
}

clean_function_parameters :: proc(parameters : [dynamic]FunctionParameter, options : ^GeneratorOptions, baseTab : string) -> string {
    output := "";

    // Special case: function(void) does not really have a parameter
    if len(parameters) == 1 {
        if _type, ok := parameters[0].type.(BuiltinType); ok {
            if _type == BuiltinType.Void {
                return "";
            }
        }
    }

    tab := "";
    if (len(parameters) > 1) {
        output = fmt.tprint(output, "\n");
        tab = fmt.tprint(baseTab, "    ");
    }

    unamedParametersCount := 0;
    for parameter, i in parameters {
        type := clean_type(parameter.type, options);

        name : string;
        if len(parameter.name) != 0 {
            name = clean_variable_name(parameter.name, options);
        } else {
            name = fmt.tprint("unamed", unamedParametersCount);
            unamedParametersCount += 1;
        }

        output = fmt.tprint(output, tab, name, " : ");
        for dimension in parameter.dimensions {
            output = fmt.tprint(output, "[", dimension, "]");
        }
        output = fmt.tprint(output, type);
        if i != len(parameters) - 1 {
            output = fmt.tprint(output, ",\n");
        }
    }

    if (len(parameters) > 1) {
        output = fmt.tprint(output, "\n", baseTab);
    }

    return output;
}
