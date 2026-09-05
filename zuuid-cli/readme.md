### zuuid-cli

A simple example of how to use a 3rd-party library.<br/>
This is just for educational purposes.

<br/>

#### Usage

```
❯ zig build run -- -u -n 3
2C270F84-6EE2-43AD-AB43-3900B65759B0
761C4DCA-212B-4711-A108-4012D7FA881E
C2006027-EC14-47BB-92AE-6B39C880BEED
❯
```

<br/>

#### Dependencies

This example uses [zuuid](https://github.com/dxps/zuuid), with its source URL and
package hash pinned in `build.zig.zon`.

The dependency URL uses `codeload.github.com/dxps/zuuid` because `codeload.github.com`
is GitHub's archive download host. Zig downloads a `.tar.gz` snapshot of the pinned
commit over HTTPS. We switched to this URL after fetching through
`git+https://github.com/dxps/zuuid#<commit>` failed with
`error: unable to create fetch stream: EndOfStream`. The archive URL bypasses
Zig's Git fetch path; it still downloads the source from the same GitHub repository.

The more familiar `https://github.com/dxps/zuuid/archive/<commit>.tar.gz` form
redirects to GitHub's codeload host. Using that host directly makes the archive
download explicit, while the commit and package hash keep the dependency pinned.
