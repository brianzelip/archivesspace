{
  schema: {
    '$schema' => 'http://www.archivesspace.org/archivesspace.json',
    'version' => 1,
    'type' => 'object',

    'properties' => {
      'content' => {
        'type' => 'string',
        'maxLength' => 65_000,
        'ifmissing' => 'error'
      },

      'publish' => { 'type' => 'boolean' }
    }
  }
}
