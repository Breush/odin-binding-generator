/**
 * Generates vulkan bindings from its header files.
 */

package main

import "core:fmt"

import "../../bindgen"

main :: proc() {
    options : bindgen.GeneratorOptions;

    // We remove defines' prefix.
    options.definePrefixes = []string{"VK_"};
    options.defineCase = bindgen.Case.Constant;

    // Pseudo types are everything that can act as a type,
    // enum, struct, unions. In vulkan.h, they are all prefixed
    // with Vk, we remove that.
    options.pseudoTypePrefixes = []string{"Vk", "vk"};
    options.pseudoTypeTransparentPrefixes = []string{"PFN_"};

    // In the C header, functions look like vkCreateInstance(), we remove the prefix.
    options.functionPrefixes = []string{"vk"};
    options.functionCase = bindgen.Case.Snake;

    // In vulkan headers, enum like VkDebugReportObjectTypeEXT
    // have values names such as VK_DEBUG_REPORT_OBJECT_TYPE_INSTANCE_EXT.
    // With the following options, we will remove the repeated "VK_DEBUG_REPORT_OBJECT_TYPE_"
    // from the enum value. Notice the "EXT" part being projected at the end,
    // thus it is configured as a postfix below.
    // Generated value will be accessible with vk.DebugReportObjectTypeEXT.Instance,
    // this follow vulkan.hpp project convention.
    options.enumValuePrefixes = []string{"VK_"};
    options.enumValuePostfixes = []string{"_BIT", "BEGIN_RANGE", "END_RANGE", "RANGE_SIZE", "MAX_ENUM"};
    options.enumValueTransparentPostfixes = []string{"_KHR", "_EXT", "_AMD", "_NV", "_NVX", "_IMG", "_GOOGLE"};
    options.enumValueCase = bindgen.Case.Pascal;
    options.enumValueNameRemove = true;
    options.enumValueNameRemovePostfixes = []string{"FlagBits", "EXT", "KHR", "AMD", "NV", "NVX", "IMG", "GOOGLE"};

    // Vulkan header has some weird macros, we handle these here.
    options.parserOptions.customHandlers["VK_DEFINE_HANDLE"] = macro_define_handle;
    options.parserOptions.customHandlers["VK_DEFINE_NON_DISPATCHABLE_HANDLE"] = macro_define_handle;
    options.parserOptions.customExpressionHandlers["VK_MAKE_VERSION"] = macro_make_version;

    // Vulkan also has platform-dependent defines that are confusing when parsing,
    // we remove them here.
    options.parserOptions.ignoredTokens = []string{"VKAPI_PTR", "VKAPI_CALL", "VKAPI_ATTR"};

    // Here, we effectively generate the file from vulkan_core.h only.
    // Platform-dependent APIs are in different headers.
    bindgen.generate(
        packageName = "vk",
        foreignLibrary = "system:vulkan",
        outputFile = "./examples/vulkan/generated/vulkan-core.odin",
        headerFiles = []string{"./examples/vulkan/headers/vulkan_core.h"},
        options = options,
    );
}

// Original macros:
// #define VK_DEFINE_HANDLE(object) typedef struct object##_T* object;
// #define VK_DEFINE_NON_DISPATCHABLE_HANDLE(object) typedef struct object##_T* object;
macro_define_handle :: proc(data : ^bindgen.ParserData) {
    bindgen.eat_token(data); // "VK_DEFINE_HANDLE" or "VK_DEFINE_NON_DISPATCHABLE_HANDLE"
    bindgen.check_and_eat_token(data, "(");
    object := bindgen.parse_identifier(data);
    bindgen.check_and_eat_token(data, ")");

    structName := fmt.tprint(object, "T");

    structNode : bindgen.StructDefinitionNode;
    structNode.name = structName;
    append(&data.nodes.structDefinitions, structNode);

    sourceType : bindgen.IdentifierType;
    sourceType.name = structName;

    typedefNode : bindgen.TypedefNode;
    typedefNode.name = object;
    typedefNode.sourceType = sourceType;
    append(&data.nodes.typedefs, typedefNode);
}

// Original macro
// #define VK_MAKE_VERSION(major, minor, patch) (((major) << 22) | ((minor) << 12) | (patch))
macro_make_version :: proc(data : ^bindgen.ParserData) -> bindgen.LiteralValue {
    bindgen.check_and_eat_token(data, "VK_MAKE_VERSION");
    bindgen.check_and_eat_token(data, "(");
    major := bindgen.evaluate_i64(data);
    bindgen.check_and_eat_token(data, ",");
    minor := bindgen.evaluate_i64(data);
    bindgen.check_and_eat_token(data, ",");
    patch := bindgen.evaluate_i64(data);
    bindgen.check_and_eat_token(data, ")");

    return (((major) << 22) | ((minor) << 12) | (patch));
}
