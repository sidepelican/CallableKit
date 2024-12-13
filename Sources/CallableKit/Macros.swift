@attached(
    peer,
    names: prefixed(configure), suffixed(Stub)
)
public macro Callable() = #externalMacro(module: "CallableKitMacros", type: "CallableMacro")
