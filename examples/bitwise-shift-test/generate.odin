/**
 * Test for parsing.
 */

package main

import "../../bindgen"

main :: proc() {
    options : bindgen.GeneratorOptions;

    bindgen.generate(
        packageName = "bitwise-shift-test",
        foreignLibrary = "",
        outputFile = "./examples/bitwise-shift-test/generated/bitwise-shift-test.odin",
        headerFiles = []string {
            "./examples/bitwise-shift-test/headers/source.h",
        },
        options = options,
    );
}
