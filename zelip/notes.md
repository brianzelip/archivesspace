# Notes for ANW-953-login-panel

## Ticket

[ANW-953](https://archivesspace.atlassian.net/browse/ANW-953)

## Design goal

![goal](goal.png)

## Related files

- `frontend/app/views/shared/_header_global.html.erb`
- `frontend/app/views/layouts/application.html.erb`
- `frontend/app/views/welcome/index.html.erb`
- `frontend/app/helpers/welcome_helper.rb`
- `frontend/app/views/shared/_login.html.erb`
- `frontend/app/controllers/session_controller.rb`
- `frontend/config/locales/en.yml`
- `frontend/app/views/shared/_header_user.html.erb`
  - need to remove everything after the else on line 98, and figure out if ruby `if` needs an `else`, if so, have to figure out with what to replace the content; what gets removed from here is what should go to the Welcome view (ie: it contains/starts the login form); it will change though, ie, it will no longer have a `<li>` as root, there won't be an `<a>` parent of the partial `shared/login`, it will just be about rendering the partial!
- `frontend/app/views/401.html.erb`
- `frontend/app/views/403.html.erb`
- `frontend/app/controllers/welcome_controller.rb`
- `frontend/config/locales/help/en.yml`
- `frontend/config/initializers/help.rb`

## Scope of task

- The question mark next to the sign in button, which represents/is a link to the "ArchivesSpace Help Center" is implicated in this task.
