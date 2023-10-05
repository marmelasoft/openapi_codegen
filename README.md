# OpenAPI Code Generation

Code generator that ingest a OpenAPI Specification and writes the structs that represent resources of that given specification and also builds the client based on the paths.

Currently supports two types of generation:

* [Tesla](https://hexdocs.pm/tesla/readme.html) - Generates a module with a Tesla client.
* [Req](https://hexdocs.pm/req/readme.html) - Generates a module using Req.

By default we're using Jason for encoding and decoding of structs

Does not require you to install extra dependencies as we're using

## Roadmap

- [ ] Support YAML specification parsing
- [ ] Support Inheritance and Polymorphism
- [ ] Add typespecs to generated Structs
- [ ] Add typespecs to Client
- [ ] Generate tests for Client

## Installation

Install it using:

```sh
mix do local.rebar --force, local.hex --force
mix escript.install hex openapi_codegen
```

## Usage

Generating a Tesla client using PetStore example:

`openapi_codegen --tesla --output-path lib openapi_petstore.json`

Generating a Req client using PetStore example:

`openapi_codegen --req --output-path lib openapi_petstore.json`

This examples will generate your code in your folder `lib` and also create a `lib/components` with all the structs.

Learn more on how to use it with `openapi_codegen --help`.
