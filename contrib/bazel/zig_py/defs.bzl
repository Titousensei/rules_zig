load("//bazel/py:def.bzl", "py_library")
load("@rules_zig//zig:defs.bzl", "zig_shared_library")

def zig_py_library(
        name,
        main,
        srcs = [],
        deps = [],
        **kwargs):

    # macos / linux only; windows should be .dll
    filename_so = 'lib' + name + '.so'

    name_so = name + '_SO'
    name_zig = name + '_ZIG'

    zig_shared_library(
        name = name_zig,
        main = main,
        deps = deps,
    )

    native.genrule(
        name = name_so,
        srcs = [":" + name_zig],
        outs = [filename_so],
        cmd = "cp $< $@",
    )

    native.py_library(
        name = name,
        srcs = [],
        data = [filename_so],
    )
