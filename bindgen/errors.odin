package bindgen

import "core:fmt"
import "core:os"

seenWarnings : map[string]bool;

print_warning :: proc(args : ..any) {
    message := tcat(..args);

    if !seenWarnings[message] {
        fmt.eprint("[bindgen] Warning: ", message, "\n");
        seenWarnings[message] = true;
    }
}

print_simple_error :: proc(data : ^ParserData, message : string, loc := #caller_location) {
    print_error(data, loc, message);
}

print_error :: proc(data : ^ParserData, loc := #caller_location, args : ..any) {
    message := tcat(..args);

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

    fmt.eprint("[bindgen] Error: ", message, "\n");
    fmt.eprintf("[bindgen] ... from internal %s:%d\n", loc.procedure, loc.line);
    fmt.eprintf("[bindgen] ... while parsing %s:%d within this context:\n", data.file, line);
    fmt.eprint("> ", extract_string(data, min, max), "\n");

    os.exit(1);
}
