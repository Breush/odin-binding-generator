/**
 * Odin binding generator from C header data.
 */

package bindgen

import "core:os"
import "core:fmt"
import "core:runtime"

GeneratorOptions :: struct {
    // Variable
    variableCase : Case,

    // Defines
    definePrefixes : []string,
    defineTransparentPrefixes : []string,
    definePostfixes : []string,
    defineTransparentPostfixes : []string,
    defineCase : Case,

    // Pseudo-types
    pseudoTypePrefixes : []string,
    pseudoTypeTransparentPrefixes : []string,
    pseudoTypePostfixes : []string,
    pseudoTypeTransparentPostfixes : []string,
    pseudoTypeCase : Case,

    // Functions
    functionPrefixes : []string,
    functionTransparentPrefixes : []string,
    functionPostfixes : []string,
    functionTransparentPostfixes : []string,
    functionCase : Case,

    // Enum values
    enumValuePrefixes : []string,
    enumValueTransparentPrefixes : []string,
    enumValuePostfixes : []string,
    enumValueTransparentPostfixes : []string,
    enumValueCase : Case,
    enumValueNameRemove : bool,
    enumValueNameRemovePostfixes : []string,

    parserOptions : ParserOptions,
}

GeneratorData :: struct {
    handle : os.Handle,
    nodes : Nodes,

    // References
    options : ^GeneratorOptions,
}

generate :: proc(
    packageName : string,
    foreignLibrary : string,
    outputFile : string,
    headerFiles : []string,
    options : GeneratorOptions,
) {
    data : GeneratorData;
    data.options = &options;

    // Outputing odin file
    errno : os.Errno;
    data.handle, errno = os.open(outputFile, os.O_WRONLY | os.O_CREATE | os.O_TRUNC);
    if errno != 0 {
        fmt.print_err("[bindgen] Unable to write to output file ", outputFile, " (", errno ,")\n");
        return;
    }
    defer os.close(data.handle);

    fmt.fprint(data.handle, "package ", packageName, "\n");
    fmt.fprint(data.handle, "\n");
    fmt.fprint(data.handle, "foreign import \"", foreignLibrary, "\"\n");
    fmt.fprint(data.handle, "\n");

    // Parsing header files
    for headerFile in headerFiles {
        bytes, ok := os.read_entire_file(headerFile);
        if !ok {
            fmt.print_err("[bindgen] Unable to read file ", headerFile, "\n");
            return;
        }

        // We fuse the SOAs
        headerNodes := parse(bytes, options.parserOptions);
        merge_nodes(&data.nodes.defines, &headerNodes.defines);
        merge_nodes(&data.nodes.enumDefinitions, &headerNodes.enumDefinitions);
        merge_nodes(&data.nodes.unionDefinitions, &headerNodes.unionDefinitions);
        merge_nodes(&data.nodes.structDefinitions, &headerNodes.structDefinitions);
        merge_nodes(&data.nodes.functionDeclarations, &headerNodes.functionDeclarations);
        merge_nodes(&data.nodes.typeAliases, &headerNodes.typeAliases);
    }

    // Exporting
    export_defines(&data);
    export_type_aliases(&data);
    export_enums(&data);
    export_structs(&data);
    export_unions(&data);

    // Foreign block for functions
    foreignLibrarySimple := simplify_library_name(foreignLibrary);
    fmt.fprint(data.handle, "@(default_calling_convention=\"c\")\n");
    fmt.fprint(data.handle, "foreign ", foreignLibrarySimple, " {\n");
    fmt.fprint(data.handle, "\n");

    export_functions(&data);

    fmt.fprint(data.handle, "}\n");
}

// system:foo.lib -> foo
simplify_library_name :: proc(libraryName : string) -> string {
    startOffset := 0;
    endOffset := len(libraryName);

    for c, i in libraryName {
        if startOffset == 0 && c == ':' {
            startOffset = i + 1;
        }
        else if c == '.' {
            endOffset = i;
            break;
        }
    }

    return libraryName[startOffset:endOffset];
}

merge_nodes :: proc(nodes : ^$T, headerNodes : ^T) {
    for node in headerNodes {
        append(nodes, node);
    }
}