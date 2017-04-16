# Code Tidbit
Browse and Create Powerful Tutorials

### Set Up

##### Local Dependencies

The project only has 3 local dependencies, `node` and `npm`, and `mongodb`.
  - node ~ V6.0.0
  - npm ~ V3.10.3
  - monodb ~ V3.2.9

You don't _need_ these versions, but it's more likely to work properly if at least the major versions are correct.

##### Project Dependencies

Once you have those local dependencies, simply run `./bin/install.sh` to install all node/elm modules as well as
typings...that's it!

### Developing

To develop run `./bin/dev.sh` which will compile and run your backend express server as well as compiling your frontend
and hosting it through webpack with `devServer`. This **will** live-reload your webapp, and we cache the frontend
application state, so it ends up _basically_ hot-reloading.

##### IDE

I use Atom (auto-completion on frontend and backend!). Plugins:
  - elmjutsu : A combination of elm goodies wrapped up in one plugin.
  - elm-format : Allows you to run elm-format on save, very convenient.
  - atom-typescript : the only typescript plugin you will ever need.

### Production

TODO @nateabele add your side of the story
  - How are we actually calling the node process (to make it restarts if it crashes for instance)
  - How are we gonna deploy the frontend/backend/migrations
  - A mention of the DB
  - Just document everything...documentation is a priority on CodeTidbit

##### Backend

Currently the backend does not build to different targets, it takes in configuration through flags, so build it normally
and then just call it in prod mode with the required flags.

```bash
# Note that you must be in the `backend` directory when building the backend.
backend: ./node_modules/.bin/tsc
backend: ./node_modules/.bin/babel . --out-dir dist --source-maps --ignore lib,node_modules;
backend: node ./dist/src/main.js --mode=prod --is-https=false --port=80 --db-url="<mongodb-url>" --session-secret-key=dev-secret-key
```

It will throw an error if you forget to pass the required flags and you ran in "prod" mode.

##### Frontend

The frontend needs to be compiled to static files so it builds to different targets. It's all built with
[webpack 1.x](http://webpack.github.io/docs/), to build for production do:

```bash
# Note that you must be in the `frontend` directory when you build the frontend.
frontend: ./node_modules/.bin/webpack --config webpack.production.config.js
```

### Project File Structure

Let's keep it simple...
  - frontend in `/frontend`
  - backend in `/backend`
  - tooling scripts in `/bin`

As well, the [frontend README](/frontend/README.md) and the [backend README](/backend/README.md) each have a segment on
their file structure.
