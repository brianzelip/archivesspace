{
  schema: {
    '$schema' => 'http://www.archivesspace.org/archivesspace.json',
    'version' => 1,
    'parent' => 'abstract_name',
    'type' => 'object',

    'properties' => {
      'primary_name' => { 'type' => 'string', 'maxLength' => 255, 'ifmissing' => 'error' },
      'title' => { 'type' => 'string', 'maxLength' => 16_384 },
      'name_order' => { 'type' => 'string', 'ifmissing' => 'error', 'dynamic_enum' => 'name_person_name_order' },
      'prefix' => { 'type' => 'string', 'maxLength' => 65_000 },
      'rest_of_name' => { 'type' => 'string', 'maxLength' => 65_000 },
      'suffix' => { 'type' => 'string', 'maxLength' => 65_000 },
      'fuller_form' => { 'type' => 'string', 'maxLength' => 65_000 },
      'number' => { 'type' => 'string', 'maxLength' => 255 }
    }
  }
}
