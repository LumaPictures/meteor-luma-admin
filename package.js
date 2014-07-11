Package.describe({
  summary: "Administrative views and helpers for luma apps"
});

Package.on_use(function (api, where) {
  api.use([
    'coffeescript',
    'underscore',
    'collection2',
    'simple-schema',
    'luma-router',
    'luma-ui',
    'jquery-select2'
  ],[ 'client', 'server' ]);

  // for helpers
  api.use([
    'jquery',
    'ui',
    'templating',
    'spacebars'
  ], [ 'client' ]);

  api.export([
    'Luma'
  ], ['client','server']);

  api.add_files([
    'lib/luma-admin.coffee'
  ], [ 'client', 'server' ]);

  api.add_files([
    'lib/views/admin/admin.html',
    'lib/views/admin/admin.coffee'
  ], [ 'client' ]);
});

Package.on_test(function (api) {
  api.use([
    'coffeescript',
    'luma-admin',
    'tinytest',
    'test-helpers'
  ], ['client', 'server']);

  api.add_files([
    'tests/luma-admin.test.coffee'
  ], ['client', 'server']);
});