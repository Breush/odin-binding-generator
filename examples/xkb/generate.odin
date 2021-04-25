/**
 * Generates XCB bindings from its header files.
 */

package main

import "../../bindgen"

main :: proc() {
    options : bindgen.GeneratorOptions;
    options.mode = "jai";

    options.functionPrefixes = []string{"xkb_"};
    options.variableCase = bindgen.Case.Camel;

    options.definePrefixes = []string{"XKB_"};
    options.defineCase = bindgen.Case.Unknown; // Keep, otherwise clash between things like XKB_KEY_Etilde and XKB_KEY_etilde

    options.pseudoTypePrefixes = []string{"xkb_"};
    options.pseudoTypePostfixes = []string{"_t"};
    options.pseudoTypeCase = bindgen.Case.Pascal;

    options.enumValuePrefixes = []string{"XKB_"};
    options.enumValueCase = bindgen.Case.Pascal;
    options.enumValueNameRemove = true;
    options.enumValueNameRemovePostfixes = []string{"_t", "Flags"};

    bindgen.generate(
        packageName = "xkb",
        foreignLibrary = "libxkbcommon",
        outputFile = "./examples/xkb/generated/xkb.jai",
        headerFiles = []string{"./examples/xkb/headers/xkbcommon.h",
                               "./examples/xkb/headers/xkbcommon-keysyms.h",
                               "./examples/xkb/headers/xkbcommon-x11.h"},
        options = options,
    );
}
