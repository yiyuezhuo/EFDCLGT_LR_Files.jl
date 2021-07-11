
# EFDCLGT_LR_Files.jl

IO related part of the Julia port of [Python version](https://github.com/yiyuezhuo/IWIND-LR-TOOLS).

Implements `save` and `load` mapping for some `EFDCLGT_LR` related Fortran "Card" IO.

While this module tried to implement the `FileIO` interface, the `add_format` would be called from this module so it will violate the standard of the `FileIO`. However, `EFDCLGT_LR` is not a well known program so it's not reasonable to PR them and hijack the `*.inp` extension (Their [doc](https://github.com/JuliaIO/FileIO.jl/blob/bf57b7f62f74b1ed55481684c406ba83415a713b/docs/src/registering.md#argument-magic)  had said something like `.out` should not be registered in `FileIO`). It's strange that Julia encourages such centralization design such as `General registry`, `FileIO` and even GitHub usage...

Tested on `EFDCLGT_LR_ver4.17.exe`.

## Tests

Define following environment variables:

* `WATER_ROOT`: Points to a directory containing the executable file (i.e. `EFDCLGT_LR_ver4.17.exe`).
* `WATER_UPSTREAM`: Contains upstream input files which will override `WATER_ROOT` files, for example:

```
$WATER_UPSTREAM/0/qser.inp
$WATER_UPSTREAM/0/wqpsc.inp
$WATER_UPSTREAM/1/qser.inp
$WATER_UPSTREAM/1/wqpsc.inp
...
```

## Notes

While the program is expected to run at least few minutes in practice, the pre-compiling time is not huge. However, it will still be painful for someone who is familiar with Python, check [PackageCompiler.jl](https://github.com/JuliaLang/PackageCompiler.jl) to avoid this cost if you want to place it in productive environment.
