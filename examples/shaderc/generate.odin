/**
 * Generates shaderc bindings from its header files.
 */

package main

import "core:fmt"

import "../../bindgen"

main :: proc() {
    options : bindgen.GeneratorOptions;
    options.mode = "jai";

    options.variableCase = bindgen.Case.Camel;
    options.definePrefixes = []string{"SHADERC_"};
    options.pseudoTypePrefixes = []string{"shaderc_"};
    options.defineCase = bindgen.Case.Constant;
    options.pseudoTypeCase = bindgen.Case.Pascal;
    options.functionPrefixes = []string{"shaderc_"};
    options.enumValuePrefixes = []string{"shaderc_"};
    options.enumValueCase = bindgen.Case.Pascal;
    options.enumValueNameRemove = true;
    options.parserOptions.ignoredTokens = []string{"SHADERC_EXPORT"};

    bindgen.generate(
        packageName = "shaderc",
        foreignLibrary = "libshaderc",
        outputFile = "./examples/shaderc/generated/shaderc.jai",
        headerFiles = []string{"./examples/shaderc/headers/shaderc.h", "./examples/shaderc/headers/env.h", "./examples/shaderc/headers/status.h"},
        options = options,
    );
}
