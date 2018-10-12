package bindgen

import "core:fmt"
import "core:strconv"

// Evaluates an expression to a i64, without checking.
evaluate_i64 :: proc(data : ^ParserData) -> i64 {
    ok : bool;
    value : LiteralValue;

    value, ok = evaluate(data);
    return value.(i64);
}

// Evaluate an expression, returns whether it succeeded.
evaluate :: proc(data : ^ParserData) -> (LiteralValue, bool) {
    return evaluate_level_4(data);
}

// @note Evaluate levels numbers are based on
// https://en.cppreference.com/w/c/language/operator_precedence.

// Additive level.
evaluate_level_4 :: proc(data : ^ParserData) -> (value : LiteralValue, ok : bool) {
    value, ok = evaluate_level_3(data);
    if !ok do return;

    token := peek_token(data);
    if token == "+" {
        v : LiteralValue;
        eat_token(data);
        v, ok = evaluate_level_4(data);
        value = value.(i64) + v.(i64);
    }
    else if token == "-" {
        v : LiteralValue;
        eat_token(data);
        v, ok = evaluate_level_4(data);
        value = value.(i64) - v.(i64);
    }

    return;
}

// Multiplicative level.
evaluate_level_3 :: proc(data : ^ParserData) -> (value : LiteralValue, ok : bool) {
    value, ok = evaluate_level_2(data);
    if !ok do return;

    token := peek_token(data);
    if token == "*" {
        v : LiteralValue;
        eat_token(data);
        v, ok = evaluate_level_3(data);
        value = value.(i64) * v.(i64);
    }
    else if token == "/" {
        v : LiteralValue;
        eat_token(data);
        v, ok = evaluate_level_3(data);
        value = value.(i64) / v.(i64);
    }

    return;
}

// Prefix level.
evaluate_level_2 :: proc(data : ^ParserData) -> (value : LiteralValue, ok : bool) {
    token := peek_token(data);

    // Bitwise not
    if token == "~" {
        check_and_eat_token(data, "~");
        value, ok = evaluate_level_2(data);
        value = ~value.(i64);
    }
    else {
        // @note Should call evaluate_level_1, but we don't have that because we do not dereferenciation.
        value, ok = evaluate_level_0(data);
    }

    return;
}

// Does not try to compose with arithmetics, it just evaluates one single expression.
evaluate_level_0 :: proc(data : ^ParserData) -> (value : LiteralValue, ok : bool) {
    ok = true;
    value = 0;
    token := peek_token(data);

    // Parentheses
    if token == "(" {
        value, ok = evaluate_parentheses(data);
    }
    // Number literal
    else if (token[0] == '-') || (token[0] >= '0' && token[0] <= '9') {
        value = evaluate_number_literal(data);
    }
    // String literal
    else if token[0] == '"' {
        value = evaluate_string_literal(data);
    }
    // Knowned literal
    else if token in data.knownedLiterals {
        value = evaluate_knowned_literal(data);
    }
    // Custom expression
    else if token in data.options.customExpressionHandlers {
        value = data.options.customExpressionHandlers[token](data);
    }
    else {
        fmt.print("[bindgen] Warning: Unknown token ", token, " for expression evaluation.\n");
        ok = false;
        return;
    }

    return;
}

evaluate_parentheses :: proc(data : ^ParserData) -> (value : LiteralValue, ok : bool) {
    check_and_eat_token(data, "(");
    value, ok = evaluate(data);
    check_and_eat_token(data, ")");
    return;
}

evaluate_number_literal :: proc(data : ^ParserData) -> i64 {
    token := parse_any(data);
    value := strconv.parse_i64(token);
    return value;
}

evaluate_string_literal :: proc(data : ^ParserData) -> string {
    token := parse_any(data);
    return token;
}

evaluate_knowned_literal :: proc(data : ^ParserData) -> LiteralValue {
    token := parse_any(data);
    return data.knownedLiterals[token];
}
