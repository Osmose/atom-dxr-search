# Atom DXR Search

Atom DXR Search is an [Atom][] package for performing [DXR][] searches. It
allows users to search DXR from within the Atom interface and jump to matches
if they've got the matching tree open within the editor.

__Note:__ This package requires you to be able to connect to a running DXR
instance, which usually means you need internet access to use it.

![Screenshot of package](http://www.mkelly.me/atom-dxr-search/screenshot.png)

[Atom]: https://atom.io/
[DXR]: https://dxr.mozilla.org/

## Usage

Hit `Cmd-Alt-J`/`Ctrl-Alt-J` to open the search dialog. Enter your query and
hit Return to submit the search. The results will be displayed below the search
bar. If there are more results than the per-page limit configured in the package
settings, there will be a "Show More" button at the bottom of the results that
will load more results when clicked.

If you have the tree you're searching open in the current project, clicking on
any of the filenames or matching lines will open that file in a new tab.

You can also remap the command to any key you want. For example, add the
following to your keymap to map `Ctrl-Alt-G` to open the dialog:

```cson
'atom-workspace':
  'ctrl-alt-g': 'atom-dxr-search:toggle'
```

## Settings:

<dl>
  <dt>Server</dt>
  <dd>
    Base URL of the server to query when searching. Defaults to
    `https://dxr.mozilla.org`.
  </dd>

  <dt>Tree</dt>
  <dd>Name of the code tree to search. Defaults to `mozilla-central`.</dd>

  <dt>Results Per Page</dt>
  <dd>Number of files to show per page of results. Defaults to `10`.</dd>
</dl>

## License

Licensed under the MIT License. See `LICENSE` for details.
