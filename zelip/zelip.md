# ANW-700 notes

## Related files

- `frontend/app/views/resources/_show_inline.html.erb`
- `frontend/app/views/related_accessions/_show.html.erb`, called from above; LINE 20 is where the related accession's identifier is rendered in the RESOURCE RECORD view; we need to find where the comporable render spot is in the RESOURCE EDIT view
- `frontend/app/views/related_accessions/_template.html.erb`
- `frontend/app/models/resource.rb`: defines the `related_accessions` method
- `frontend/app/views/related_accessions/_template.html.erb`
- `frontend/app/views/accessions/_linker.html.erb`, rendered via above \_template
- `frontend/app/views/resources/_form_container.html.erb`, contains 'resource_related_accessions'
- `frontend/app/views/shared/_subrecord_form.html.erb`, called from directly above
- `frontend/app/assets/javascripts/linker.js`: the data that gets rendered in the `section#resource_related_accessions_` has to come from the linker
- `frontend/app/views/search/_listing.html.erb`: i think _this_ is where the select-accession-modal html comes from
- `frontend/app/helpers/application_helper.rb`: this is what is actually writing the text of the related accession in edit mode/read mode
