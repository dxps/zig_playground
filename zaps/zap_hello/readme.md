## Zap Hello

A _hello world_ like project as a starting point for playing with zap.

<br/>

### Run

Use the standard `zig build run` to start it.

For a better development experience (have the app restarted on code changes), you can:

-   install [air](https://github.com/air-verse/air) and
-   use `./run-dev.sh` to start the app

<br/>

### Usage

See in its output the paths to call using HTTP GET.

<br/>

---

### Project creation notes

-   project created using `zig init`
-   `zap` dependency was added using:<br/>
    `zig fetch --save "git+https://github.com/zigzap/zap#v0.9.1"`
-   small cleanup: removed `src/root.zig` and related elements (in `build.zig.zon` file).
