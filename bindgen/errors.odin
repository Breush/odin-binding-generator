package bindgen

import "core:fmt"

seenWarnings : map[string]bool;

print_warning :: proc(args : ..any) {
    message := fmt.tprint(..args);

    if !seenWarnings[message] {
        fmt.print_err("[bindgen] Warning: ", message, "\n");
        seenWarnings[message] = true;
    }
}
