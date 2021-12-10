# Change log

## [v1.3.0] - 2021-12-10

[Diff](https://github.com/abeiderman/active_record_data_loader/compare/v1.2.0...v1.3.0)

### Changes:
* Replace the `:file` output option with simply accepting an optional file path as `output`. A SQL script file will be generated in addition to loading the data into the database.
* Identify and handle unique indexes by attempting to generate unique values. Add configuration options for behavior around duplicate rows.

## [v1.2.0] - 2021-11-14

[Diff](https://github.com/abeiderman/active_record_data_loader/compare/v1.1.0...v1.2.0)

### Changes:
* Add `:file` output option for generating a SQL script instead of loading the data into the database.
* Fix some connection handling issues when a custom connection factory is provided.

## [v1.1.0] - 2021-05-01

[Diff](https://github.com/abeiderman/active_record_data_loader/compare/v1.0.2...v1.1.0)

### Changes:
* Bump ruby version requirement to >= 2.5
* Bump activerecord requirement to >= 5.0

## [v1.0.2] - 2019-07-05

[Diff](https://github.com/abeiderman/active_record_data_loader/compare/v1.0.1...v1.0.2)

### Changes:
* Add support for MySQL enums
* Accept a connection factory lambda as part of the configuration

## [v1.0.1] - 2019-06-16

[Diff](https://github.com/abeiderman/active_record_data_loader/compare/v1.0.0...v1.0.1)

### Changes:
* Generate values for datetime column types. This also fixes the fact that `created_at` and `updated_at` were not being populated by default.

## [v1.0.0] - 2019-06-15

Initial stable release

[v1.0.0]: https://github.com/abeiderman/active_record_data_loader/releases/tag/v1.0.0
[v1.0.1]: https://github.com/abeiderman/active_record_data_loader/releases/tag/v1.0.1
[v1.0.2]: https://github.com/abeiderman/active_record_data_loader/releases/tag/v1.0.2
[v1.1.0]: https://github.com/abeiderman/active_record_data_loader/releases/tag/v1.1.0
[v1.2.0]: https://github.com/abeiderman/active_record_data_loader/releases/tag/v1.2.0
[v1.3.0]: https://github.com/abeiderman/active_record_data_loader/releases/tag/v1.3.0
