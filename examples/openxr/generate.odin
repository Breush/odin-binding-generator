/**
 * Generates openxr bindings from its header files.
 */

package main

import "core:fmt"

import "../../bindgen"

main :: proc() {
    options : bindgen.GeneratorOptions;
    options.mode = "jai";

    // We remove defines' prefix.
    options.definePrefixes = []string{"XR_"};
    options.defineCase = bindgen.Case.Constant;

    // Pseudo types are everything that can act as a type,
    // enum, struct, unions.
    options.pseudoTypePrefixes = []string{"Xr", "xr"};
    options.pseudoTypeTransparentPrefixes = []string{"PFN_"};

    // In the C header, functions look like xrCreateInstance(), we remove the prefix.
    options.functionPrefixes = []string{"xr"};
    options.functionCase = bindgen.Case.Snake;

    options.enumValuePrefixes = []string{"XR_"};
    options.enumValueCase = bindgen.Case.Pascal;
    options.enumValueNameRemove = true;

    // Openxr also has platform-dependent defines that are confusing when parsing,
    // we remove them here.
    options.parserOptions.ignoredTokens = []string{"XRAPI_PTR", "XRAPI_CALL", "XRAPI_ATTR", "XR_MAY_ALIAS"};

    // Here, we effectively generate the file from openxr_core.h only.
    // Platform-dependent APIs are in different headers.
    bindgen.generate(
        packageName = "xr",
        foreignLibrary = "libopenxr",
        outputFile = "./examples/openxr/generated/openxr.jai",
        headerFiles = []string{"./examples/openxr/headers/openxr-preprocessed.h"},
        options = options,
    );
}
