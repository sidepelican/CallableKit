@attached(
    peer,
    names: arbitrary
)
public macro Callable() = #externalMacro(module: "CallableKitMacros", type: "CallableMacro")
