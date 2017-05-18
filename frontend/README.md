# Frontend

The frontend is fully coded in Elm. If you are new to Elm, it is worth checking out the
[main tutorial](https://guide.elm-lang.org/) to get a better grip of what is going on.

### File Structure and Organization

##### Default Services

All file that go here represent default services that can be used from project to project, you should **not** put stuff
in DefaultServices that is app-specific. Current default services include:
- ArrayExtra : Extra helpers for handling arrays.
- CommonSubPageUtil : Helpers for dealing with the `(Model, Shared, Cmd msg)` type, passed into all sub-pages.
- Editable : Convenience for editing fields in a model.
- Http : Does the annoying part of handling http errors.
- InfixFunctions : Common general infix functions should be put here.
- LocalStorage : Handles interacting with localStorage.
- Sort : Contains helpers for sorting, most importantly sorting by multiple fields.
- Util : Put all random functions that are useful in this file ("utilities").

##### Elements

Whenever you have an element on the page that you want to reuse in multiple places, it's good to put it in `Elements/`.
A good test of whether something belongs in `Elements/` is "does it have it's own view and styles", if yes, then it does
belong here, if it's just helper methods for a certain data structure then it belongs in `Models/`. Each elm file will
be accompanied by a matching scss file.

Elements is split in two sub-directories reflecting the 2 types of elements: `Simple` and `Complex`.

###### Simple Elements

Simple elements represent styled views, they expose a `view` function which can be directly dropped into any page,
they often can take in `RenderConfig` which allows you to specify any generic parts of the view (such as events).

###### Complex Elements

Complex elements not only have a `view`, but also their own `Msg`, `Model`, and corresponding `Update`. With complex
elements it's no good to _just_ drop it in the view, you also have to wire up the `update`.

##### JSON

There is 2 situations where we need to encode/decode to/from JSON.

1. We are sending/receiving things from the API.
2. We want to encode our model so we can cache it in localStorage.

Due to this, we need a lot of encoders/decoders (especially because of 2). To keep this from dirtying the code and
making it harder to find helper methods which we use frequently, we keep all encoders/decoders in `JSON/`. For the most
part, every file in here matches to a file in `Models/` or `Elements/`.

##### Models

All application models should go here, this is not the same as the `Model.elm` files which represent the application
model, rather these models represent things like a `User` or a `Route`. Often these models will be sent/received from
the API but they will also be for random models just used on the frontend, in Elm helper methods are king so making
models whenever you have a certain format of data you are handling is a great way to keep helper-methods organized and
views thinner.

##### Pages

All pages go in this directory, the base page is at root level and nested pages go inside sub-directories such as
`Pages/Home/` for the `Home` page.

Each page has the following files:
- Init.elm
  - Each page is responsible for showing how to initialize it's model that way when a user first comes to the website we
    know how to populate the full model with defaults.
- JSON.elm
  - Handles encoding/decoding that pages `Model`.
- Messages.elm
  - The `Msg` that will be passed to the `update` function of that page.
- Model.elm
  - The model that represents all the data needed for that page.
- Styles.scss
  - The styles for that page.
- Update.elm
  - The `update` function for the page, the `case ... of` will be taking in a message of the type declared in
    `Messages.elm`. Note that for nested pages `update` returns it's model *and* `shared` that way it can make changes
    to it's own model/`shared` but not another pages model.
- View.elm
  - The view for the page. This could have multiple routes, but it should be one individual page on the website.

##### Styles

- Page styles are in the same folder `/Pages/x/styles.scss`.
- Element styles go parallel to the element, eg `/Elements/Simple/Editor.elm` and `/Elements/Simple/Editor.scss`.
- We also have some global styles (self-explanatory names):
  - Styles/Mixins.scss
  - Styles/Global.scss
  - Styles/Variables.scss

##### Top Level Files

- **Api.elm** :  All the connections to the API will be through this module.
- **Flags.elm** : The flags being passed into the application (from javascript -> Elm).
- **index.html** : The only html file, where we embed our elm app.
- **index.js** : The only JS file, handles the JS side of ports.
- **Main.elm** : Initialize the elm application here.
- **Ports.elm** : All ports should be in this module, this is the elm side of the ports.
- **ProjectTypeAliases.elm** : Common project aliases for clarity (such as `TidbitID` for `String`) should be put here.
- **Subscriptions.elm** : All subscriptions should be in this module.

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
