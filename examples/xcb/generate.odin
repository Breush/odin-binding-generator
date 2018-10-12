/**
 * Generates XCB bindings from its header files.
 */

package main

import "../../bindgen"

main :: proc() {
    options : bindgen.GeneratorOptions;

    options.functionPrefixes = []string{"xcb_"};
    options.variableCase = bindgen.Case.Camel;

    // We remove defines' prefix.
    options.definePrefixes = []string{"XCB_"};
    options.defineCase = bindgen.Case.Constant;

    // Pseudo types are everything that can act as a type,
    // enum, struct, unions.
    options.pseudoTypePrefixes = []string{"xcb_"};
    options.pseudoTypePostfixes = []string{"_t"};
    options.pseudoTypeCase = bindgen.Case.Pascal;

    // In xproto.h, xcb_visual_class_t enum has
    // enum values that look like XCB_VISUAL_CLASS_STATIC_GRAY.
    options.enumValuePrefixes = []string{"XCB_"};
    options.enumValueCase = bindgen.Case.Pascal;
    options.enumValueNameRemove = true;
    options.enumValueNameRemovePostfixes = []string{"_t"};

    bindgen.generate(
        packageName = "xcb",
        foreignLibrary = "system:xcb",
        outputFile = "./examples/xcb/generated/xcb.odin",
        headerFiles = []string{"./examples/xcb/headers/xcb.h", "./examples/xcb/headers/xproto.h"},
        options = options,
    );
}
