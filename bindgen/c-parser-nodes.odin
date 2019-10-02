package bindgen

DefineNode :: struct {
    name : string,
    value : LiteralValue,
}

StructDefinitionNode :: struct {
    name : string,
    members : [dynamic]StructOrUnionMember,
    forwardDeclared : bool,
}

UnionDefinitionNode :: struct {
    name : string,
    members : [dynamic]StructOrUnionMember,
}

EnumDefinitionNode :: struct {
    name : string,
    members : [dynamic]EnumMember,
}

FunctionDeclarationNode :: struct {
    name : string,
    returnType : Type,
    parameters : [dynamic]FunctionParameter,
}

TypedefNode :: struct {
    name : string,
    sourceType : Type,
    dimension : u64,  // Array dimensions
}

Nodes :: struct {
    defines : [dynamic]DefineNode,
    enumDefinitions : [dynamic]EnumDefinitionNode,
    unionDefinitions : [dynamic]UnionDefinitionNode,
    structDefinitions : [dynamic]StructDefinitionNode,
    functionDeclarations : [dynamic]FunctionDeclarationNode,
    typedefs : [dynamic]TypedefNode,
}

LiteralValue :: union {
    i64,
    f64,
    string,
}

Type :: union {
    BuiltinType,
    StandardType,
    PointerType,
    IdentifierType,
    FunctionPointerType,
}

BuiltinType :: enum {
    Unknown,
    Void,
    Int,
    UInt,
    LongInt,
    ULongInt,
    LongLongInt,
    ULongLongInt,
    ShortInt,
    UShortInt,
    Char,
    SChar,
    UChar,
    Float,
    Double,
    LongDouble,
}

// Not defined by C language but in <stdint.h>
StandardType :: enum {
    Unknown,
    Int8,
    Int16,
    Int32,
    Int64,
    UInt8,
    UInt16,
    UInt32,
    UInt64,
    Size,
    SSize,
    PtrDiff,
    UIntPtr,
    IntPtr,
}

PointerType :: struct {
    type : ^Type, // Pointer is there to prevent definition cycle. Null means void.
}

IdentifierType :: struct {
    name : string,
}

FunctionPointerType :: struct {
    name : string,
    returnType : ^Type, // Pointer is there to prevent definition cycle. Null means void.
    parameters : [dynamic]FunctionParameter,
}

EnumMember :: struct {
    name : string,
    value : i64,
    hasValue : bool,
}

StructOrUnionMember :: struct {
    name : string,
    type : Type,
    dimensions : [dynamic]u64,  // Array dimensions
}

FunctionParameter :: struct {
    name : string,
    type : Type,
    dimensions : [dynamic]u64,  // Array dimensions
}
