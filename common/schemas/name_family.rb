{
  schema: {
    '$schema' => 'http://www.archivesspace.org/archivesspace.json',
    'version' => 1,
    'parent' => 'abstract_name',
    'type' => 'object',

    'properties' => {
      'family_name' => { 'type' => 'string', 'maxLength' => 65_000, 'ifmissing' => 'error' },
      'prefix' => { 'type' => 'string', 'maxLength' => 65_000 }
    }
  }
}
