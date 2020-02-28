# Notes on [ANW-921](https://archivesspace.atlassian.net/browse/ANW-921)

My first public interface work.

## Problem

Here's the view of the current citation modal:

![PUI citation modal](./problem.png)

The live path is `/resources/:resource_id`

## Related files

- `public/app/views/resources/show.html.erb`
  - modal_actions partial is used from here
- `public/app/views/shared/\_modal_actions.html.erb`
- `public/app/assets/javascripts/cite.js`
- `public/app/views/resources/infinite.html.erb`
  - modal_actions partial is used from here
- `public/app/views/resources/infinite.html.erb`
  - modal_actions partial is used from here
- `public/app/views/shared/_page_actions.html.erb`: this list contains the cite button that opens the cite modal
- `public/app/views/shared/_cite_page_action.html.erb`
- `public/app/views/shared/_modal.html.erb`
- `public/app/controllers/cite_controller.rb`

## Data flow

1. on a resources view like, `public/app/views/resources/show.html.erb`
2. click the citation button, which is rendered via `_page_actions` and `_cite_page_actions` views
3. the modal is triggered from the existing DOM and made visible; the modal comes from the `_modal` view via the `_modal_actions` view, and via `cite.js`
