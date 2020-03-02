# ANW-1052 notes

https://archivesspace.atlassian.net/browse/ANW-1052

The PR that introduced this bug, https://github.com/archivesspace/archivesspace/pull/1705

## Related files

- `frontend/app/assets/javascripts/rde.js`,
  - specifically, see https://github.com/archivesspace/archivesspace/blob/dd4b4ac03c7e1f7e204aab4b624c921e6b1ce372/frontend/app/assets/javascripts/rde.js#L994
- `frontend/app/views/shared/_rde.html.erb`
- `frontend/app/views/archival_objects/_rde_templates.html.erb`
  - this is the where the one required column gets created (L 11)
- `frontend/app/views/digital_object_components/_rde_templates.html.erb`
- `frontend/config/locales/en.yml`

## Trace data flow

1. In the rde modal view, there's the "Fill Column" button that has `.fill-column`
2. in the js, there's a function `initFillFeature` which gets the button on line 417
3. the js listens for button clicks on L 422, then slides in the fill form
4. the basic and sequence fill forms are already set up in the DOM, just not visually displayed

I suspect it has to do with the `populateColumnSelector()` funciton as used in the Fill Column form on L 442; `populateColumnSelector()` is defined on L 980

## Solution idea after undoing PR #1705

It's not really about Fill Column, it's more about the column visibility button that was bugged out by [PR #1705](https://github.com/archivesspace/archivesspace/pull/1705/commits)

What #1705 did was add the following to `frontend/app/assets/javascripts/rde.js`:

```js
if ($(this).hasClass('required')) {
  $option.attr('disabled', true);
  var colId = $(this).attr('id');
  if (VISIBLE_COLUMN_IDS != null && $.inArray(colId, VISIBLE_COLUMN_IDS) < 0) {
    VISIBLE_COLUMN_IDS.push(colId);
  }
  showColumn($(this).attr('columnIndex'));
}
```

## Terseness in documentation b/c don't want to put too much energy on explaining the real deal

So it's not about Fill Column at all, it's actually about `initColumnShowHideWidget()` in rde.js

## PR Solution

The solution here is to decrease the scope of PR #1705 by moving the work from the global `populateColumnSelector()`, to the local `initColumnShowHideWidget` via a `disableRequiredColumns()`.

Tests successfully against the use case in [ANW-1048](https://archivesspace.atlassian.net/browse/ANW-1048) ✌️
