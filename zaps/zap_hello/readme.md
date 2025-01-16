## Zap Hello

A hello world like project as a starting point for playing with zap.

<br/>

### Run

Use the standard `zig build run` to start it.

<br/>

### Usage

See in its output the paths to call using HTTP GET.

<br/>

---

### Project creation notes

After `zig init`, the `zap` dependency was added using `zig fetch --save "git+https://github.com/zigzap/zap#v0.9.1"`. A small cleanup to remove `src/root.zig` and related elements in `build.zig.zon` was also done.
