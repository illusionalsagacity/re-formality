# Contributing

## Requesting a feature

If you would like to request a feature, please, [create an issue](https://github.com/MinimaHQ/re-formality/issues/new).

## Reporting a bug

If you want to report a bug, there are few options:

1. You can contribute a minimal falling test with your use case. It would make things easier for us to proceed with the fix.
2. You can contribute a minimal falling test and a fix. Even better :)
3. If you don't feel like contributing a test, please, [create an issue](https://github.com/MinimaHQ/re-formality/issues/new) with as many details as possible and we will try to figure out something.

### Contributing a test

There might be 2 types of issues:

1. Compile-time error.
2. Runtime error (related to logic or just runtime crashes).

If you are facing the former, add PPX test in [`ppx/test`](./ppx/test).<br>
If you are facing the latter, add integration test in [`specs`](./specs).

See the corresponding README for details.

It would be great if you could reduce your test case to minimal size. I.e. instead of copy/pasting code from your app as is, try to remove unrelated parts and keep only what's related to the error.

## Technical details

### Repository structure

```shell
- docs/       # Documentation
- examples/   # Examples
- lib/        # ReScript library
  - src/      # ReScript library sources
- ppx/        # PPX
  - bin/      # PPX binary
  - lib/      # PPX implementation
  - test/     # PPX tests
- specs/      # Integration tests
```

### Setup

This repo uses `yarn` workspaces to manage frontend related dependencies and `opam` to manage PPX related dependencies (optionally, you can use `nix` shell instead of `opam` for development).

Install Yarn dependencies:

```shell
yarn install
```

Build ReScript library:

```shell
# In lib/ folder
yarn rescript build
```

Build public interface of the ReScript lib:

```shell
# Apparently `rescript` doesn't have `bsb -install` counterpart
# So you need to build any app in this workspace that relies on `re-formality`

# E.g. in ./examples folder
yarn rescript build
```

**Opam flow**
Install Esy dependencies:

```shell
opam init -a --disable-sandboxing --compiler=4.14.1
opam install . --deps-only --with-test
```

Build PPX:

```shell
opam exec -- dune build
```

**Nix/Devbox flow**
Considering you are already in Devbox shell, build PPX:

```shell
dune build
```

## Debugging the PPX

### Viewing Generated AST

To debug what the PPX generates, you can dump the AST output of a ReScript file:

```shell
# Dump the PPX output for a specific file
dune exec -- ppx/bin/bin.exe examples/src/LoginForm.res -dump-ast

# Or use the ReScript compiler's PPX dump flag
rescript build -- -dsource
```

### Inspecting Generated Code

The PPX transforms `%form(...)` extensions into ReScript modules. To see the generated code:

1. Build the PPX: `dune build ppx/bin/bin.exe`
2. Run `yarn res:build` in the `examples/` directory
3. Check the generated `.res.js` files to understand what code was produced

### Key PPX Files

| File                                      | Purpose                                                                                         |
| ----------------------------------------- | ----------------------------------------------------------------------------------------------- |
| `ppx/lib/Uncurried.ml`                    | Utilities for generating uncurried functions (wraps with `Function$` and `res.arity` attribute) |
| `ppx/lib/Form_ValidatorsRecord.ml`        | Processes the `validators` record, ensures `eq` field exists                                    |
| `ppx/lib/Form_InitialFieldsStatusesFn.ml` | Generates the `initialFieldsStatuses` function                                                  |
| `ppx/lib/Form_UseFormFn.ml`               | Generates the main `useForm` hook                                                               |

### ReScript 12 Compatibility Notes

ReScript 12 introduced uncurried-by-default mode which required PPX changes:

1. **Function wrapping**: Functions must be wrapped with `Function$` constructor and `res.arity` attribute:

   ```ocaml
   (* In Uncurried.ml *)
   let fn ~loc ~arity fx =
     let arity_attr = ... (* res.arity attribute *) in
     Exp.construct ~loc ~attrs:[arity_attr]
       { txt = Longident.Lident "Function$"; loc }
       (Some fx)
   ```

2. **Equality operator**: ReScript 12 doesn't support `( = )` syntax. Use `==` operator instead:

   ```ocaml
   (* Generate: (a, b) => a == b *)
   Exp.fun_ Nolabel None [%pat? a]
     (Exp.fun_ Nolabel None [%pat? b]
       [%expr a == b])
   ```

3. **Function application**: Use `res.uapp` attribute for uncurried function applications.

### Running PPX Tests

```shell
# Run all PPX tests
dune test

# Run tests and show output
dune test --force
```

### Common Issues

**"This function only accepts N arguments"**
The generated function is missing proper arity marking. Ensure `Uncurried.fn ~arity:N` wraps the function expression.

**"The value = can't be found"**
The PPX is generating `( = )` syntax which is invalid in ReScript 12. Use `==` operator instead.

**"Function$ is not a constructor"**
Check that the `res.arity` attribute is correctly attached to the `Function$` construct.
