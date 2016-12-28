# Frontend

The frontend is fully coded in Elm. If you are new to Elm, it is worth checking
out the [main tutorial](https://guide.elm-lang.org/) to get a better grip of
what is going on.

### File Structure

##### Components

All components go in this directory, the base component is at root level
and nested components go inside directories such as `Components/Home`.

Each component has the following files:
- Init.elm
  - Each component is responsible for showing how to initialize it's model that
    way when a user first comes to the website we know how to populate the full
    model with defaults.
- Messages.elm
  - The `Msg` that will be passed to the `update` function of that component.
- Model.elm
  - The model that represents all the data needed for that component. The base
    component will put nested models in itself such as `homeComponent`. This is
    done for organizational purposes to make the model layout simpler and to
    avoid namespace collisions. All `update` functions (for nested
    components) will be given their model and `shared`,
    which is how all the components share data with each other (eg. the route
    the website is currently on would go in `shared` as all components may need
    to access this!). This means that a component can only modify it's own model
    and `shared`, but it could not possibly modify another component's model,
    this is good as it makes your components more isolated! If the homeComponent
    did need to modify something in the welcomeComponent, then that "something"
    should be in `shared`, that's the point of `shared`.
- Styles.scss
  - The styles for that component.
- Update.elm
  - The `update` function for the component, the `case ... of` will be taking
    in a message of the type declared in `Messages.elm`. Note that for nested
    components `update` returns it's model *and* `shared` that way it can make
    changes to it's own model/`shared` but not another components model.
- View.elm
  - The view for the component, eg. it could be the view for the welcome page
    or the home page. Note that I have a single `View.elm` for both the home
    profile page and the home home page. A `View.elm` need not correspond to a
    single route, but rather it is simply the view for a single component. A
    component will likely have multiple routes.

##### Default Services

All file that go here represent default services that can be used from project
to project, you should **not** put stuff in DefaultServices that is
app-specific. Current default services include:
- Http (does the annoying part of handling http errors)
- Util (put all random functions that are useful in this file, "utilities")
- LocalStorage (handles interacting with localStorage)

##### Models

All application models should go here, this is not the same as the `Model.elm`
files which represent the application model, but rather models which represent
things like a `User` or a `Route`. Often these models will be sent/received
from the API so they will often have the functions:
- `encoder`
- `decoder`

Note that there are two types of encoders/decoders you will see:
- `encoder` / `cacheEncoder`
- `decoder` / `cacheDecoder`

The reason you see a duplicate of everything with a `cache` prefix is because
there are two situations where we encode our data:
1. We are sending data to the API, in this case we want to encode everything
"normally".
2. We are `cache`ing the data in local storage, in this case we need to be a bit
careful because we don't want to `cache` passwords, we erase all sensitive data.

Follow the existing name convention so it's easy to find and use the correct
encoder/decoder based on the situation.

##### Styles

While we put component styles in the directories of their component (so it's
easy to find while developing) we also have some styles not specific to any
component, these are placed in this directory:
- Mixins.scss
  - Just useful mixins...
- Global.scss
  - Global styles, such as styles on `html` or `body` or classes that we want
    to be able to use in any component.
- Variables.scss
  - Just a list of app scss variables such as the colors used in the app.

##### Top Level Files

- Api.elm
  - All the connections to the API will be through this module, notice the
    naming convention of starting with `get` or `post`.
- Config.elm
  - Configuration for the app
- DefaultModel.elm
  - Provides the default model for the entire application
- Main.elm
  - Initialize the elm application here
- Ports.elm
  - All ports should be in this module
- Router.elm
  - Contains app-specific routing helpers such as `navigateTo` and
    `parseLocation`.
- Subscriptions.elm
  - All subscriptions should be in this module

### Style Conventions

Thanks to [elm-format](https://github.com/avh4/elm-format)
99% of formatting is done automatically! There are only a few things to keep
in mind outside of elm-format to make your code as clear as possible.

1. No ghost imports (unused imports)
1. Imports should all be sorted alphabetically
1. Imports should not be multi-lined (it's ok if it's long)
1. `module <name> exposing` should be multi-lined if it is to long
  - This is multi-lined because:
    - it's first so it's less disruptive if it's multi-lined.
    - it's more likely to be helpful to see what a module exports so it's
      actually worth the extra lines.
1. Pick a line-length and stick to it, you should either use 80 (what I use) or
   100, those are relatively standard. With elm-format handling formatting
   automatically, you need only "break the line" and re-run elm-format to have
   it automatically make the formatting correct for a short-line format.
