/**
 * Generates mini_al bindings from its header files.
 */

package main

import "../../bindgen"

main :: proc() {
    options : bindgen.GeneratorOptions;

    bindgen.generate(
        packageName = "minial",
        foreignLibrary = "system:mini_al",
        outputFile = "./examples/mini-al/generated/mini-al.odin",
        headerFiles = []string{"./examples/mini-al/headers/mini-al-preprocessed.h"},
        options = options,
    );
}
