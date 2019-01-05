/**
 * Generates zlib bindings from its header files.
 */

package main

import "../../bindgen"

main :: proc() {
    options : bindgen.GeneratorOptions;

    bindgen.generate(
        packageName = "minial",
        foreignLibrary = "system:zlib",
        outputFile = "./examples/zlib/generated/zlib.odin",
        headerFiles = []string{
            "./examples/zlib/headers/zlib-preprocessed.h",
            // "./examples/zlib/headers/zconf-preprocessed.h",
        },
        options = options,
    );
}
