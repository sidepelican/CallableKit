@attached(
    peer,
    names: prefixed(configure)
)
public macro Callable() = #externalMacro(module: "CallableKitMacros", type: "CallableMacro")
