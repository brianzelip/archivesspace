# ANW-172 notes

[ticket](https://archivesspace.atlassian.net/browse/ANW-172)

## Related files

- `frontend/app/assets/javascripts/largetree.js.erb`
  - `LargeTree.prototype.renderRoot`
- `frontend/app/assets/javascripts/largetree_dragdrop.js.erb`
- `backend/app/model/large_tree.rb`
- `frontend/app/views/resources/edit.html.erb`
- `frontend/app/views/shared/_largetree.html.erb`
- `frontend/app/assets/javascripts/tree.js.erb`
- `frontend/app/controllers/resources_controller.rb`
- `frontend/app/assets/stylesheets/archivesspace/largetree.less`
- `frontend/app/assets/javascripts/archival_object.crud.js` (found by search for '#archival_object_form')
- `frontend/app/views/archival_objects/_show_inline.html.erb` - where the html starts getting written on the below section w/ the date string problem; I think, but am not sure, that the `<% define_template... >` bit is just an inline-template definition instead of a template being defined in its own file, then the bit at the end of this file is what actually renders the defined template from earlier in the file -- ASK LORA!
- `frontend/app/helpers/aspace_form_helper.rb` - found via 'readonly-context' search
- `https://github.com/archivesspace/archivesspace/blob/master/backend/app/model/archival_object.rb#L64-L82` - this is the file that Lora pointed out to me ass the real culprit in this issue; in particular, the `.first` in the following lambda:

```rb
date_label = json.has_key?('dates') && json['dates'].length > 0 ?
  lambda {|date|
    if date['expression']
      date['expression']
    elsif date['begin'] and date['end']
      "#{date['begin']} - #{date['end']}"
    else
      date['begin']
    end
  }.call(json['dates'].first) : false
```

## Related functions

```js
function Tree(
  datasource_url,
  tree_container,
  form_container,
  toolbar_container,
  root_uri,
  read_only,
  root_record_type
) {
  var self = this;

  self.datasource = new TreeDataSource(datasource_url);

  var tree_renderer = renderers[root_record_type];

  self.toolbar_renderer = new TreeToolbarRenderer(self, toolbar_container);

  self.root_record_type = root_record_type;

  self.large_tree = new LargeTree(
    self.datasource,
    tree_container,
    root_uri,
    read_only,
    tree_renderer,
    function() {
      self.ajax_tree = new AjaxTree(self, form_container);
      self.resizer = new TreeResizer(self, tree_container);
    },
    function(node, tree) {
      self.toolbar_renderer.render(node);
    }
  );

  if (!read_only) {
    self.dragdrop = self.large_tree.addPlugin(
      new LargeTreeDragDrop(self.large_tree)
    );
  }

  self.large_tree.setGeneralErrorHandler(function(failure_type) {
    if (failure_type === 'fetch_node_failed') {
      /* This can happen when the user was logged out behind the scenes. */
      $('#tree-unexpected-failure').slideDown();
    }
  });
}
```

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

## Update after back end work

From Lora

> I resolved ANW-172 as far as the form header goes/touching the erb template we looked at together, but that didn't resolve the tree rendering.
>
> I dug a bit deeper and found that that tree display string does exist in a js.erb here --> https://github.com/archivesspace/archivesspace/blob/master/frontend/app/assets/javascripts/tree_renderers.js.erb#L91-L99

### More related files

- `frontend/app/assets/javascripts/tree_renderers.js.erb`
