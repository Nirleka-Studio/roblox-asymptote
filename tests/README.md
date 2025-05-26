## Unit Testing

Due to Rojo, unit testing while still having the foundational code of the entire engine has become easier.

It is recommended that developers use a seperate place for testing.

### How it works

Each folder will act as a seperate project. The `default.project.json` file in each testing directory will reference the files in `src/`, allowing you to still access the modules just like when you're working on the main codebase.