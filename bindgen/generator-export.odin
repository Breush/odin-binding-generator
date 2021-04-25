package bindgen

import "core:os"
import "core:fmt"

export_defines :: proc(data : ^GeneratorData) {
    for node in data.nodes.defines {
        defineName := clean_define_name(node.name, data.options);

        // @fixme fprint of float numbers are pretty badly handled,
        // just has a 10^-3 precision.
        fcat(data.handle, defineName, " :: ", node.value, ";\n");
    }
    fcat(data.handle, "\n");
}

export_typedefs :: proc(data : ^GeneratorData) {
    for node in data.nodes.typedefs {
        name := clean_pseudo_type_name(node.name, data.options);
        type := clean_type(data, node.type);
        if name == type do continue;
        fcat(data.handle, name, " :: ", type, ";\n");
    }
    fcat(data.handle, "\n");
}

export_enums :: proc(data : ^GeneratorData) {
    for node in data.nodes.enumDefinitions {
        enumName := clean_pseudo_type_name(node.name, data.options);
        fcat(data.handle, enumName, data.options.mode == "jai" ? " :: enum s32 {" :" :: enum i32 {");

        postfixes : [dynamic]string;
        enumName, postfixes = clean_enum_name_for_prefix_removal(enumName, data.options);

        // Changing the case of postfixes to the enum value one,
        // so that they can be removed.
        enumValueCase := find_case(node.members[0].name);
        for postfix, i in postfixes {
            postfixes[i] = change_case(postfix, enumValueCase);
        }

        // Merging enum value postfixes with postfixes that have been removed from the enum name.
        for postfix in data.options.enumValuePostfixes {
            append(&postfixes, postfix);
        }

        export_enum_members(data, node.members, enumName, postfixes[:]);
        fcat(data.handle, data.options.mode == "jai" ? "}\n" : "};\n");
        fcat(data.handle, "\n");
    }
}

export_structs :: proc(data : ^GeneratorData) {
    for node in data.nodes.structDefinitions {
        structName := clean_pseudo_type_name(node.name, data.options);
        fcat(data.handle, structName, " :: struct {");
        export_struct_or_union_members(data, node.members);
        fcat(data.handle, data.options.mode == "jai" ? "}\n" : "};\n");
        fcat(data.handle, "\n");
    }
}

export_unions :: proc(data : ^GeneratorData) {
    for node in data.nodes.unionDefinitions {
        unionName := clean_pseudo_type_name(node.name, data.options);
        fcat(data.handle, unionName, data.options.mode == "jai" ? " :: union {" : " :: struct #raw_union {");
        export_struct_or_union_members(data, node.members);
        fcat(data.handle, data.options.mode == "jai" ? "}\n" : "};\n");
        fcat(data.handle, "\n");
    }
}

export_functions :: proc(data : ^GeneratorData) {
    for node in data.nodes.functionDeclarations {
        functionName := clean_function_name(node.name, data.options);
        if data.options.mode == "jai" {
            fcat(data.handle, functionName, " :: (");
        } else {
            fcat(data.handle, "    @(link_name=\"", node.name, "\")\n");
            fcat(data.handle, "    ", functionName, " :: proc(");
        }
        parameters := clean_function_parameters(data, node.parameters, data.options.mode == "jai" ? "" : "    ");
        fcat(data.handle, parameters, ")");
        returnType := clean_type(data, node.returnType);
        if len(returnType) > 0 {
            fcat(data.handle, " -> ", returnType);
        }
        if data.options.mode == "jai" {
            fcat(data.handle, " #foreign ", data.foreignLibrary, " \"", node.name ,"\";\n");
        } else {
            fcat(data.handle, " ---;\n");
        }
        fcat(data.handle, "\n");
    }
}

export_enum_members :: proc(data : ^GeneratorData, members : [dynamic]EnumMember, enumName : string, postfixes : []string) {
    if (len(members) > 0) {
        fcat(data.handle, "\n");
    }
    for member in members {
        name := clean_enum_value_name(member.name, enumName, postfixes, data.options);
        if len(name) == 0 do continue;
        fcat(data.handle, "    ", name);
        if member.hasValue {
            fcat(data.handle, data.options.mode == "jai" ? " :: " : " = ", member.value);
        }
        fcat(data.handle, data.options.mode == "jai" ? ";\n" : ",\n");
    }
}

export_struct_or_union_members :: proc(data : ^GeneratorData, members : [dynamic]StructOrUnionMember) {
    if (len(members) > 0) {
        fcat(data.handle, "\n");
    }
    for member in members {
        type := clean_type(data, member.type, "    ");
        name := clean_variable_name(member.name, data.options);
        fcat(data.handle, "    ", name, " : ", type, data.options.mode == "jai" ? ";\n" : ",\n");
    }
}
