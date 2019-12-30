# Odin binding generator

An [Odin](https://github.com/odin-lang/Odin) library
to convert a **C header file into an Odin binding file**.

## Current status

The library has been tested against multiple C-libraries,
such as **xcb** or **vulkan**, and the generated bindings
are working fine.

When new tricky cases appear while converting a well-known library header,
these are considered as bugs and are expected to be resolved quickly.

The C-parser is not expected to be perfect. Notably, "bugs" based on
complex macros expansions are considered "intended". The goal is not
to parse and resolve C wrong design decisions, but just be able
to get a `.odin` file that works with most of C libraries.

## Usage

```go
import "bindgen"

main :: proc() {
    options : bindgen.GeneratorOptions;
    bindgen.generate(
        packageName = "vk",
        foreignLibrary = "system:vulkan",
        outputFile = "vulkan.odin",
        headerFiles = []string{"./vulkan.h"},
        options = options,
    );
}
```

See the `examples` to show options tweaking in practice (such as case conventions),
run them from the root folder: `odin run ./examples/vulkan/generate.odin`.

These examples generate bindings from the C headers of the library
into `./examples/vulkans/generated/` and can be tested with
`odin run ./examples/vulkan/vulkan/test.odin`.

*Please note that these examples are not meant to generate up-to-date bindings,
but to test said bindings.*

One way to prevent errors with C macros is to run the preprocessor first, like so:
```bash
cat zlib.h | grep -v "#include " | gcc -E - -o - | grep -v "# " > zlib-preprocessed.h
```

### Generator options

#### Variables

Variables, in this context, are function parameters and struct members names.

```C
void function(int variableName);
```

| Description | Generated code |
| ----------- | -------------- |
| Enforce a new case syntax for variables.<br/> `Case.Unknown` keeps original. <ul><li>**`variableCase`**` = Case.Snake`</li></ul> | `function :: proc(variable_name : int) ---;` |

#### Defines

Parsing C `#define`, macros will be ignored. Other directives like `#ifdef` or `#pragma` are fully ignored too.

```C
#define AB_MY_BEST_NUMBER 4
```

| Description | Generated code |
| ----------- | -------------- |
| A list of prefixes that should be removed from define names.<br/> These are recursive and will be removed as long as long possible. <ul><li>**`definePrefixes`**` = []string{"AB_"}`</li></ul> Postfix variant **`definePostfixes`**. | `MY_BEST_NUMBER :: 4;` |
| A list of prefixes that should be kept but ignored while prefix removing. <ul><li>`definePrefixes = []string{"MY_"}`</li><li>**`defineTransparentPrefixes`**` = []string{"AB_"}`</li></ul> Postfix variant **`defineTransparentPostfixes`**. | `AB_BEST_NUMBER :: 4;` |
| Enforce a new case syntax for defines.<br/> `Case.Unknown` keeps original. <ul><li>**`defineCase`**` = Case.Camel`</li></ul> | `abMyBestNumber :: 4;` |

#### Pseudo-types

A pseudo-type is either a `struct`, `union`, `enum` or `typedef` alias.
That is to say anything that can be used as a type.

```C
typedef struct {} ab_my_shape_ext;
```

| Description | Generated code |
| ----------- | -------------- |
| A list of prefixes that should be removed from pseudo-type names.<br/> These are recursive and will be removed as long as long possible. <ul><li>**`pseudoTypePrefixes`**` = []string{"ab_"}`</li></ul> Postfix variant **`pseudoTypePostfixes`**. | `my_shape_ext :: struct {}` |
| A list of prefixes that should be kept but ignored while prefix removing. <ul><li>`pseudoTypePrefixes = []string{"my_"}`</li><li>**`pseudoTypeTransparentPrefixes`**` = []string{"ab_"}`</li></ul> Postfix variant **`pseudoTypeTransparentPostfixes`**. | `ab_shape_ext :: struct {}` |
| Enforce a new case syntax for pseudo-types.<br/> `Case.Unknown` keeps original. <ul><li>**`pseudoTypeCase`**` = Case.Pascal`</li></ul> | `AbMyShapeExt :: struct {}` |

#### Functions

Only functions declarations are parsed, definitions are ignored.

```C
uint32_t abMyFunction();
```

| Description | Generated code |
| ----------- | -------------- |
| A list of prefixes that should be removed from function names.<br/> These are recursive and will be removed as long as long possible. <ul><li>**`functionPrefixes`**` = []string{"ab"}`</li></ul> Postfix variant **`functionPostfixes`**. | `MyFunction :: proc() -> u32 ---;` |
| A list of prefixes that should be kept but ignored while prefix removing. <ul><li>`functionPrefixes = []string{"My"}`</li><li>**`functionTransparentPrefixes`**` = []string{"ab"}`</li></ul> Postfix variant **`functionTransparentPostfixes`**. | `abFunction :: proc() -> u32 ---;` |
| Enforce a new case syntax for functions.<br/> `Case.Unknown` keeps original. <ul><li>**`functionCase`**` = Case.Pascal`</li></ul> | `ab_my_function :: proc() -> u32 ---;` |

#### Enum values

Enum values are members of enums.

```C
typedef enum {
    AB_MY_SHAPE_EXT_SQUARE, // The enum name is repeated in the value.
    AB_MY_SHAPE_CIRCLE_EXT, // Here, the EXT part has been moved to the end.
} abMyShapeExt;
```

| Description | Generated code |
| ----------- | -------------- |
| A list of prefixes that should be removed from enum values.<br/> These are recursive and will be removed as long as long possible. <ul><li>**`enumValuePrefixes`**` = []string{"AB_"}`</li></ul> Postfix variant **`enumValuePostfixes`**. | `abMyShapeExt :: enum i32 {`<br/>`MY_SHAPE_EXT_SQUARE,`<br/>`MY_SHAPE_CIRCLE_EXT`<br/>`}` |
| A list of prefixes that should be kept but ignored while prefix removing. <ul><li>`enumValuePrefixes = []string{"MY_"}`</li><li>**`enumValueTransparentPrefixes`**` = []string{"AB_"}`</li></ul> Postfix variant **`enumValueTransparentPostfixes`**. | `abMyShapeExt :: enum i32 {`<br/>`AB_SHAPE_EXT_SQUARE,`<br/>`AB_SHAPE_CIRCLE_EXT`<br/>`}` |
| Enforce a new case syntax for enum values.<br/> `Case.Unknown` keeps original. <ul><li>**`enumValueCase`**` = Case.Pascal`</li></ul> | `abMyShapeExt :: enum i32 {`<br/>`AbMyShapeExtSquare,`<br/>`AbMyShapeCircleExt`<br/>`}` |
| Whether we should remove the prefix of an enum value if it matches its enum name.<br/> The case variant of the enum value is detected automatically. <ul><li>**`enumValueNameRemove`**` = true`</li></ul> | `abMyShapeExt :: enum i32 {`<br/>`SQUARE,`<br/>`AB_MY_SHAPE_CIRCLE_EXT`<br/>`}` |
| The postfixes to be removed from the enum name while removing it from enum values.<br/> If any postfix is removed, we try to remove it from all the enum values too (adapting the case). <ul><li>`enumValueNameRemove = true`</li><li>**`enumValueNameRemovePostfixes`**` = []string{"Ext"}`</li></ul> | `abMyShapeExt :: enum i32 {`<br/>`EXT_SQUARE,`<br/>`CIRCLE`<br/>`}` |

### Parser options

One can specify options for the parser, through the generator options.
The purpose is mainly to handle custom macros, as the binding generator won't
handle them.

| Description |
| ----------- |
| A list of tokens that should be understood as whitespaces.<br/> <ul><li>**`ignoredTokens`**` = []string{"AB_INLINE"}`</li></ul> |
| A map of handlers used to understand a part of code that starts with the key as token. See `./examples/vulkan/generate.odin` to find a use case.<br/> <ul><li>**`customHandlers`**`["AB_DEFINE"] = proc(data : ^ParserData) { ... };`</li></ul> |
| A map of handlers used to understand a part of code that starts with the key as token and that generates some expression value. See `./examples/vulkan/generate.odin` to find a use case.<br/> <ul><li>**`customExpressionHandlers`**`["AB_SQRT"] = proc(data : ^ParserData) -> LiteralValue { ... };`</li></ul> |

## License

This library is MIT-licensed.
See `license.txt`.
