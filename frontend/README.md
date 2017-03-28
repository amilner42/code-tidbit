# Frontend

The frontend is fully coded in Elm. If you are new to Elm, it is worth checking
out the [main tutorial](https://guide.elm-lang.org/) to get a better grip of
what is going on.

### File Structure and Organization

##### Default Services

All file that go here represent default services that can be used from project
to project, you should **not** put stuff in DefaultServices that is
app-specific. Current default services include:
- ArrayExtra (Extra helpers for handling arrays)
- Editable (convenience for editing fields in a model)
- Http (does the annoying part of handling http errors)
- Util (put all random functions that are useful in this file, "utilities")
- LocalStorage (handles interacting with localStorage)

##### Elements

Whenever you have an element on the page that you want to reuse in multiple
places, it's good to put it in `Elements/`. A good test of whether something
belongs in `Elements/` is "does it have it's own view and styles", if yes, then
it does belong here, if it's just helper methods for a certain data structure
then it belongs in `Models/`. Each elm file will be accompanied by a matching
scss file.

##### JSON

There is 2 situations where we need to encode/decode to/from JSON.

1. We are sending/receiving things from the API.
2. We want to encode our model so we can cache it in localStorage.

Due to this, we need a lot of encoders/decoders (especially because of 2). To
keep this from dirtying the code and making it harder to find helper methods
which we use frequently, we keep all encoders/decoders in `JSON/`. For the most
part, every file in here matches to a file in `Models/` or `Elements/`.

##### Models

All application models should go here, this is not the same as the `Model.elm`
files which represent the application model, rather these models represent
things like a `User` or a `Route`. Often these models will be sent/received
from the API but they will also be for random models just used on the frontend,
in Elm helper methods are king so making models whenever you have a certain
format of data you are handling is a great way to keep helper-methods organized
and views thinner.

##### Pages

All pages go in this directory, the base page is at root level and nested pages
go inside directories such as `Pages/Home/`.

Each page has the following files:
- Init.elm
  - Each page is responsible for showing how to initialize it's model that
    way when a user first comes to the website we know how to populate the full
    model with defaults.
- Messages.elm
  - The `Msg` that will be passed to the `update` function of that page.
- Model.elm
  - The model that represents all the data needed for that page.
- Styles.scss
  - The styles for that page.
- Update.elm
  - The `update` function for the page, the `case ... of` will be taking
    in a message of the type declared in `Messages.elm`. Note that for nested
    pages `update` returns it's model *and* `shared` that way it can make
    changes to it's own model/`shared` but not another pages model.
- View.elm
  - The view for the page. This could have multiple routes, but it should be one
    individual page on the website.

##### Styles

- Page styles are in the same folder `/Pages/x/styles.scss`.
- Element styles go parallel to the element, eg `/Elements/Editor.elm` and
  `/Elements/Editor.scss`.
- We also have some global styles (self-explanatory names):
  - Mixins.scss
  - Global.scss
  - Variables.scss

##### Top Level Files

- Api.elm
  - All the connections to the API will be through this module, notice the
    naming convention of starting with `get` or `post`.
- DefaultModel.elm
  - Provides the default model for the entire application
- Main.elm
  - Initialize the elm application here
- Ports.elm
  - All ports should be in this module
- Subscriptions.elm
  - All subscriptions should be in this module

### Project Style Conventions

Thanks to [elm-format](https://github.com/avh4/elm-format)
99% of formatting is done automatically! There are only a few things to keep
in mind outside of elm-format to make your code as clear as possible.

1. Line length of 120 chars.
  - Use your discretion when long-lines improves readability and when multi-lining improves it. 120 is the cap.
1. No ghost imports (unused imports)
1. Imports should all be sorted case-sensitive natural-sorting.
1. Imports should not be multi-lined (it's ok if it's long)
1. `module <name> exposing` should be multi-lined if it is to long
  - This is multi-lined because:
    - it's first so it's less disruptive if it's multi-lined.
    - it's more likely to be helpful to see what a module exports so it's
      actually worth the extra lines.
1. Messages (`type Msg`) that are reactive should be "onX" while messages that are commanding should be `x`. Eg.
  - getX
  - onGetXSuccess
  - onGetXFailure
