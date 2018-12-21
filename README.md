# Code Tidbit

**NOT UNDER ACTIVE DEVELOPMENT**

> [ PROJECT STATUS UPDATES ]
>
> October 27th, 2017
>
> CodeTidbit is no longer being hosted on codetidbit.com, I unfortunately don't
> have the money to keep it running, and I don't have the time to keep working on it as
> I'm back in school and finishing my degree. If you're interested in forking the project
> or donating to help the keep project online, please contact me. A small donation could
> go a long way to keeping this project alive. Together we can make sharing code knowledge more
> effective!
>
> April 22nd, 2018
>
> I'm still in school but will have a bit of time this summer to continue working on
> CodeTidbit. I probably won't put it back online but I will continue adding features.
>
> December 20th, 2018
>
> I probably won't be working much more on this app, I have other ideas that take priority.
> I don't think this idea will reach fruition.

> [WARNING]
>
> This was created when Elm was newer and ideas about how to structure apps were still being developed.
> This codebase uses a component-centric approach, which is not at all ideal in Elm.
> I'll be updating my [meen kickstarter](https://github.com/amilner42/meen-kickstarter) to reflect a better
> approach to developing in Elm, which is more [data structure oriented](https://www.youtube.com/watch?v=x1FU3e0sT1I).
> For this reason, **I do NOT recommend using this codebase as a guide**.


### Set Up

##### Local Dependencies

The project only has 3 local dependencies, `node` and `npm`, and `mongodb`.
  - node ~ V6.0.0
  - npm ~ V3.10.3
  - mongodb ~ V3.2.9

You don't _need_ these versions, but it's more likely to work properly if at least the major versions are correct.

##### Project Dependencies

```bash
# Npm install has hooks to install extra dependencies (elm packages + typings).
codetidbit: cd backend;
backend: npm install;
backend: cd ../frontend;
frontend: npm run reinstall;
```

### Developing

Currently everything works though npm scripts. It's best to use 2 terminals when developing, one for the frontend and
one for the backend (this keeps STDOUT less jumbled).

Terminal 1
```bash
# This will watch for changes and restart the server automatically.
cd backend;
npm start;
```

Terminal 2
```bash
# This will watch for changes and live-reload the browser.
cd frontend;
npm start;
```

##### IDE

I use Atom (auto-completion on frontend and backend!). Plugins:
  - elmjutsu : A combination of elm goodies wrapped up in one plugin.
  - elm-format : Allows you to run elm-format on save, very convenient.
  - atom-typescript : the only typescript plugin you will ever need.

##### Contributing

If you'd like to help work on CodeTidbit, it's worth shooting me an email
first (amilner42@gmail.com) and I can definitely help figure out what
you should do.

You're absolutely free to fork this project and do things your own way
as well (I encourage it!), but it is licensed under the GPL3.0 so you
must keep your modifications/extensions open source as well.

### Production

##### Backend

Currently the backend does not build to different targets, it takes in
configuration through flags, so build it normally and then just call it
in prod mode with the required flags.
```bash
# Note that you must be in the `backend` directory when building the backend.
backend: npm run build;
backend: node ./lib/src/main.js --mode=prod --is-https=... --port=... --db-url=... --session-secret-key=...
```

It will throw an error if you forget to pass the required flags and you ran in "prod" mode.

##### Frontend

The frontend needs to be compiled to static files so it builds to different targets.
It's all built with [webpack 2.x](https://webpack.js.org/concepts/), to build for production do:

```bash
# Note that you must be in the `frontend` directory when you build the frontend.
frontend: npm run build;
```

### Project File Structure

Let's keep it simple...
  - frontend in `/frontend`
  - backend in `/backend`

As well, the [frontend README](/frontend/README.md) and the [backend README](/backend/README.md)
each have a segment on their file structure.
