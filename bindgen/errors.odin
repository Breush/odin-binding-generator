package bindgen

import "core:fmt"
import "core:os"

seenWarnings : map[string]bool;

print_warning :: proc(args : ..any) {
    message := fmt.tprint(..args);

    if !seenWarnings[message] {
        fmt.print_err("[bindgen] Warning: ", message, "\n");
        seenWarnings[message] = true;
    }
}

print_error :: proc(data : ^ParserData, loc := #caller_location, args : ..any) {
    message := fmt.tprint(..args);

    min : u32 = 0;
    for i := data.offset - 1; i > 0; i -= 1 {
        if data.bytes[i] == '\n' {
            min = i + 1;
            break;
        }
    }

    max := min + 200;
    for i := min + 1; i < max; i += 1 {
        if data.bytes[i] == '\n' {
            max = i;
            break;
        }
    }

    line, _ := get_line_column(data);

    fmt.print_err("[bindgen] Error: ", message, "\n");
    fmt.print_err("[bindgen] ... from ", loc.procedure, "\n");
    fmt.print_err("[bindgen] ... at line ", line, " within this context:\n");
    fmt.print_err("> ", extract_string(data, min, max), "\n");

    os.exit(1);
}
