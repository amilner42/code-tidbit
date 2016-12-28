# Backend

The backend is fully coded in Typescript. If you are new to Typescript I
recommend reading/skimming through [basarat's guide](https://basarat.gitbooks.io/typescript/content/docs/getting-started.html),
it's a great book!

### File Structure

On the backend most files stay at top level, currently there is only one
directory (`models/`). From what I've learnt this seems to be a better practice
as it avoid nasty relative-pathing for imports and keeps the code simpler to
understand (it's a bit different on the frontend where the recursiveness of
the problem domain leads to more folders and sub-folders).

##### Models

All models used in the application as well as models designed for endpoints.

All models use `kleen` to do the runtime validation, kleen is a very simple
runtime validation library that can be found
[here](https://amilner42.github.io/kleen/).

##### Top Level Files

- db.ts
  - This module allows for connection to the database by using the `collection`
    function, eg. to get the user collection you would `collection('user')` and
    add a `.then` because as per usual it's async.
- main.ts
  - The main file, you will run this to run the full application.
- passport-local-auth-strategies.ts
  - Contains the passport strategies for signing up or signing in.
- routes.ts
  - Contains the routes (you might be used to the word _endpoints_) for the API,
    you should try to avoid putting a lot of logic in this file, simply put the
    routes (otherwise this file bloats).
- server.ts
  - Does all the configuration to get our express server up and running,
    including setting up the hosting for our static frontend.
- types.ts
  - As recommend by basarat (the typescript guy) it is nice to have a file
    where all your types live. It makes it easy to build more complex types
    without needing tons of imports. I originally had this sit in a namespace
    inside the global namespace (so you wouldn't even need to import `types.ts`)
    but do to errors with enums not compiling I switched it over to the
    `types.ts` file.
- util.ts
  - Similar to the frontend, all utilities (generally useful helper functions)
    should be put in this file.
- validifier.ts
  - Validifier is a module which contains validation helpers (such as
    `validEmail`).

##### Outside Src Directory

There are a few important folders outside the `src` directory:
- migrations
  - All migrations go here, refer to the README there to see the format of how
    to code migrations.
- tests
  - This is where all tests go, tests should end in `.test.ts`, refer to the
    existing tests (`tests/validifier.test.ts`) to see how to write tests.
- typings_manual
  - While manual typings go in `typings/`, not all modules have existing
    typings and thanks to module augmentation (introduced in TS 1.8) we can
    make our own module typings.
  - typings_manual is spit in two folders:
    - augmented_modules: Here we can make augmentations to modules that do have
      typings but where the typings are not correct (perhaps not up to date).
    - fill_in_modules: Here we create our own typings for modules that do not
      have any typings.

### Style Conventions

These are all my opinions on what keeps code clean, I make no claim with my
limited experience that these are objectively good styles to follow.
  - No `export default ...`
     - Same function can be named differently in different files :/
     - If you see a `const ...` you may think it's module-private, only to find it's exported at the bottom :/
  - `const ...` declarations at the top of the module, followed by `export const`
    - Makes it clear what's public and what's private, no surprises :)
  - `type`s at the top of the file followed by actual code, follow the same idea
    where first put private types (`const`) followed by external types
    (`export const`). The full order is:
     1. Private types
     2. Public types
     3. Private Code
     4. Public code
  - Every module should have `/// Module for ...` at the top with a brief explanation of the module.
    - Makes it simple for developers joining your team to get the big picture.
  - Docs, docs everywhere :)
