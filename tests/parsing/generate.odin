/**
 * Test for parsing.
 */

package main

import "../../bindgen"

main :: proc() {
    options : bindgen.GeneratorOptions;

    bindgen.generate(
        packageName = "parsing",
        foreignLibrary = "",
        outputFile = "./tests/parsing/generated/parsing.odin",
        headerFiles = []string{
            "./tests/parsing/headers/source.h",
        },
        options = options,
    );
}
