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
    else if name == "map" || name == "proc" || name == "c" {
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
clean_type :: proc(type : Type, options : ^GeneratorOptions, baseTab : string = "") -> string {
    if _type, ok := type.(BuiltinType); ok {
        if _type == BuiltinType.Void do return "";
        else if _type == BuiltinType.Int do return "c.int";
        else if _type == BuiltinType.UInt do return "c.uint";
        else if _type == BuiltinType.LongInt do return "c.long";
        else if _type == BuiltinType.ULongInt do return "c.ulong";
        else if _type == BuiltinType.LongLongInt do return "c.longlong";
        else if _type == BuiltinType.ULongLongInt do return "c.ulonglong";
        else if _type == BuiltinType.ShortInt do return "c.short";
        else if _type == BuiltinType.UShortInt do return "c.ushort";
        else if _type == BuiltinType.Char do return "c.char";
        else if _type == BuiltinType.SChar do return "c.schar";
        else if _type == BuiltinType.UChar do return "c.uchar";
        else if _type == BuiltinType.Float do return "c.float";
        else if _type == BuiltinType.Double do return "c.double";
        else if _type == BuiltinType.LongDouble do return "<niy>";
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
        if _type.name == "int8_t" do return "i8";
        else if _type.name == "int16_t" do return "i16";
        else if _type.name == "int32_t" do return "i32";
        else if _type.name == "int64_t" do return "i64";
        else if _type.name == "uint8_t" do return "u8";
        else if _type.name == "uint16_t" do return "u16";
        else if _type.name == "uint32_t" do return "u32";
        else if _type.name == "uint64_t" do return "u64";
        else if _type.name == "size_t" do return "c.size_t";
        else do return clean_pseudo_type_name(_type.name, options);
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

    for parameter, i in parameters {
        type := clean_type(parameter.type, options);
        name := len(parameter.name) != 0 ? clean_variable_name(parameter.name, options) : "---";
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
