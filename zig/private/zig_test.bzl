"""Implementation of the zig_test rule."""

load(
    "//zig/private/common:filetypes.bzl",
    "ZIG_C_SOURCE_EXTENSIONS",
    "ZIG_SOURCE_EXTENSIONS",
)
load("//zig/private/common:csrcs.bzl", "zig_csrcs")
load("//zig/private/common:linker_script.bzl", "zig_linker_script")
load("//zig/private/common:zig_cache.bzl", "zig_cache_output")
load("//zig/private/common:zig_lib_dir.bzl", "zig_lib_dir")
load(
    "//zig/private/providers:zig_package_info.bzl",
    "ZigPackageInfo",
    "zig_package_dependencies",
)
load(
    "//zig/private/providers:zig_settings_info.bzl",
    "ZigSettingsInfo",
    "zig_settings",
)
load(
    "//zig/private/providers:zig_target_info.bzl",
    "zig_target_platform",
)

DOC = """\
Builds a Zig test.

The target can be executed using `bazel test`, corresponding to `zig test`.

**EXAMPLE**

```bzl
load("@rules_zig//zig:defs.bzl", "zig_test")

zig_test(
    name = "my-test",
    main = "test.zig",
    srcs = [
        "utils.zig",  # to support `@import("utils.zig")`.
    ],
    deps = [
        ":my-package",  # to support `@import("my-package")`.
    ],
)
```
"""

ATTRS = {
    "main": attr.label(
        allow_single_file = ZIG_SOURCE_EXTENSIONS,
        doc = "The main source file.",
        mandatory = True,
    ),
    "srcs": attr.label_list(
        allow_files = ZIG_SOURCE_EXTENSIONS,
        doc = "Other Zig source files required to build the target, e.g. files imported using `@import`.",
        mandatory = False,
    ),
    "extra_srcs": attr.label_list(
        allow_files = True,
        doc = "Other files required to build the target, e.g. files embedded using `@embedFile`.",
        mandatory = False,
    ),
    "csrcs": attr.label_list(
        allow_files = ZIG_C_SOURCE_EXTENSIONS,
        doc = "C source files required to build the target.",
        mandatory = False,
    ),
    "copts": attr.string_list(
        doc = "C compiler flags required to build the C sources of the target.",
        mandatory = False,
    ),
    "deps": attr.label_list(
        doc = "Packages or libraries required to build the target.",
        mandatory = False,
        providers = [ZigPackageInfo],
    ),
    "linker_script": attr.label(
        doc = "Custom linker script for the target.",
        allow_single_file = True,
        mandatory = False,
    ),
    "_settings": attr.label(
        default = "//zig/settings",
        doc = "Zig build settings.",
        providers = [ZigSettingsInfo],
    ),
}

TOOLCHAINS = [
    "//zig:toolchain_type",
    "//zig/target:toolchain_type",
]

def _zig_test_impl(ctx):
    zigtoolchaininfo = ctx.toolchains["//zig:toolchain_type"].zigtoolchaininfo
    zigtargetinfo = ctx.toolchains["//zig/target:toolchain_type"].zigtargetinfo

    outputs = []

    direct_inputs = []
    transitive_inputs = []

    args = ctx.actions.args()
    args.use_param_file("@%s")

    # TODO[AH] Append `.exe` extension on Windows.
    output = ctx.actions.declare_file(ctx.label.name)
    outputs.append(output)
    args.add(output, format = "-femit-bin=%s")

    direct_inputs.append(ctx.file.main)
    direct_inputs.extend(ctx.files.srcs)
    direct_inputs.extend(ctx.files.extra_srcs)
    args.add(ctx.file.main)

    zig_csrcs(
        copts = ctx.attr.copts,
        csrcs = ctx.files.csrcs,
        inputs = direct_inputs,
        args = args,
    )

    zig_package_dependencies(
        deps = ctx.attr.deps,
        inputs = transitive_inputs,
        args = args,
    )

    zig_linker_script(
        linker_script = ctx.file.linker_script,
        inputs = direct_inputs,
        args = args,
    )

    zig_lib_dir(
        zigtoolchaininfo = zigtoolchaininfo,
        args = args,
    )

    zig_cache_output(
        actions = ctx.actions,
        name = ctx.label.name,
        outputs = outputs,
        args = args,
    )

    zig_settings(
        settings = ctx.attr._settings[ZigSettingsInfo],
        args = args,
    )

    zig_target_platform(
        target = zigtargetinfo,
        args = args,
    )

    ctx.actions.run(
        outputs = outputs,
        inputs = depset(direct = direct_inputs, transitive = transitive_inputs, order = "preorder"),
        executable = zigtoolchaininfo.zig_exe_path,
        tools = zigtoolchaininfo.zig_files,
        arguments = ["test", "--test-no-exec", args],
        mnemonic = "ZigBuildTest",
        progress_message = "Building %{input} as Zig test %{output}",
        execution_requirements = {tag: "" for tag in ctx.attr.tags},
    )

    default = DefaultInfo(
        executable = output,
        files = depset([output]),
        runfiles = ctx.runfiles(files = [output]),
    )

    return [default]

zig_test = rule(
    _zig_test_impl,
    attrs = ATTRS,
    doc = DOC,
    test = True,
    toolchains = TOOLCHAINS,
)
