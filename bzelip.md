# ANW-172 notes

[ticket](https://archivesspace.atlassian.net/browse/ANW-172)

## Related files

`frontend/app/assets/javascripts/largetree.js.erb`

## Rules

- All (elligible) dates should be displayed
- and in the case of long or unusual dates the text should wrap to a new line (see what happens currently to long record titles)
- dates should be in the order they appear in the sub-records, separated by commas
- Bulk dates (indicated by date type = Bulk Dates) should be distinguished by "bulk: "
- use the existing rules to determine which dates to display from a particular sub-record (for example, date expression takes precedence over begin/end dates)
- use the existing rules to determine when to wrap or use ellipses.

```
current sample string: title, date1
updated sample string: title, date1, bulk: date2, date3, date4
```

- Here’s where in the largetree.js.erb that that title’s being picked up → [https://github.com/archivesspace/archivesspace/blob/master/frontend/app/assets/javascripts/largetree.js.erb#L578](largetree.js.erb#L578)
