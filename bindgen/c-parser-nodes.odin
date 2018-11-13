package bindgen

DefineNode :: struct {
    name : string,
    value : LiteralValue,
}

StructDefinitionNode :: struct {
    name : string,
    members : [dynamic]StructOrUnionMember,
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
    returnType : GenericType,
    parameters : [dynamic]FunctionParameter,
}

TypeAliasNode :: struct {
    name : string,
    sourceType : GenericType,
}

Nodes :: struct {
    defines : [dynamic]DefineNode,
    enumDefinitions : [dynamic]EnumDefinitionNode,
    unionDefinitions : [dynamic]UnionDefinitionNode,
    structDefinitions : [dynamic]StructDefinitionNode,
    functionDeclarations : [dynamic]FunctionDeclarationNode,
    typeAliases : [dynamic]TypeAliasNode,
}

LiteralValue :: union {
    i64,
    f64,
    string,
}

// const char* -> prefix="const" main="char" postfix="*"
// @fixme TYPE This should be renamed BasicType and GenericType -> Type
Type :: struct {
    prefix : string,
    main : string,
    postfix : string,
}

FunctionPointerType :: struct {
    name : string,
    returnType : Type,
    parameters : [dynamic]FunctionParameter,
}

GenericType :: union {
    Type,
    FunctionPointerType,
}

EnumMember :: struct {
    name : string,
    value : i64,
    hasValue : bool,
}

StructOrUnionMember :: struct {
    name : string,
    type : GenericType,
    dimensions : [dynamic]u64,  // Array dimensions
}

FunctionParameter :: struct {
    name : string,
    type : GenericType,
    dimensions : [dynamic]u64,  // Array dimensions
}
