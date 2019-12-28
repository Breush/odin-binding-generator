/**
 * Test for parsing.
 */

package main

import "../../bindgen"

main :: proc() {
    options : bindgen.GeneratorOptions;

    bindgen.generate(
        packageName = "parsing-test",
        foreignLibrary = "",
        outputFile = "./examples/parsing-test/generated/parsing-test.odin",
        headerFiles = []string{
            "./examples/parsing-test/headers/source.h",
        },
        options = options,
    );
}
