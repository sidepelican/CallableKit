# example

This is an example of CallableKit usage.
API definition, server, and client are all implemented in one package, but each can be split up.

## Setup

Override `CallableKit` with local package.

```sh
swift package edit --path ../ CallableKit
```

## Run test

Select the server-side framework to test.

```sh
./test.sh vapor
```

```sh
./test.sh hummingbird
```

## Manual code generation

```sh
swift package --allow-writing-to-package-directory codegen
```

