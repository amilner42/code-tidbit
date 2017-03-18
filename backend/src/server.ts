/// Module for setting up the express server (all middleware).

import bodyParser from 'body-parser';
import express, { Express, Handler } from 'express';
import expressSession from 'express-session';
import sessionStore from 'connect-mongo';
import path from 'path';
import { toPairs, contains, map }   from 'ramda';
import passport from 'passport';

import { APP_CONFIG } from './app-config';
import { toMongoObjectID, collection } from './db';
import { loginStrategy, signUpStrategy } from './passport-local-auth-strategies';
import { authlessRoutes, routes } from './routes';


const MONGO_STORE = sessionStore(expressSession);

/**
 * Route-level middleware for making sure a user is authenticated, if not
 * authenticated the errorCode for not being authenticated will be sent back.
 */
const isAuthenticated = (req, res, next) => {
  if(req.isAuthenticated()) {
    next();
    return;
  }

  res.status(401).json({
    message: "You are not authorized!",
    errorCode: 1
  });
  return;
};

/**
 * Returns an express server with all the middleware setup.
 *
 * WARNING: Express middleware order matters, changing the order of your
 *          middleware can cause subtle bugs, make sure you know what you are
 *          doing when you add/change the order of things.
 *
 * NOTE: This function uses global app config from `app-config.ts`.
 */
const createExpressServer = () => {
  // The Express server.
  const server = express();

  /**
   * Sets up passport-related middleware and intilization.
   *
   * @mutates server (adds passport middleware)
   */
  const setUpPassport = () => {

    // Use the user's id for serialization.
    passport.serializeUser(function(user, done) {
      done(null, user._id);
    });

    // Deserialize from the id.
    passport.deserializeUser(function(id, done) {
      collection("users")
      .then((Users) => Users.findOne({"_id": toMongoObjectID(id)}))
      .then((User) => {
        if(!User) return done(null, false, {message: "User " + id + " does not exist"});
        done(null, User);
      })
      .catch((err) => done(err));
    });

    passport.use('sign-up', signUpStrategy);
    passport.use('login', loginStrategy);

    server.use(passport.initialize());
    server.use(passport.session());
  };

  // Parse requests as JSON, available on `req.body`.
  server.use(bodyParser.json());

  // TODO do we even want to allow cross domain requests.
  // Allow cross domain requests.
  server.use(function allowCrossDomain(req, res, next) {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    // intercept OPTIONS method
    ('OPTIONS' === req.method) ? res.send(200) : next();
  });

  // Use `expressSession` to handle storing the cookies which we send to the
  // frontend
  server.use(expressSession({
    saveUninitialized: true, // saved new sessions
    resave: false, // do not automatically write to the session store
    store: new MONGO_STORE({url: APP_CONFIG.dbUrl}),
    secret: APP_CONFIG.sessionSecretKey,
    cookie : {
      httpOnly: !APP_CONFIG.isHttps,
      maxAge: APP_CONFIG.sessionDuration
    },
    name: APP_CONFIG.sessionCookieName
  }));

  // This should be after `server.use(expressSession...`, or too many sessions
  // may be created!
  server.use(express.static('./frontend/dist'));

  // Set up passport middleware.
  setUpPassport();

  // Add all API routes.
  map(([apiUrl, handlers]) => {
    const apiUrlWithPrefix = '/api' + apiUrl;

    map(([method, handler]: [string, any]) => {
      if(authlessRoutes[apiUrl] && authlessRoutes[apiUrl][method]) {
        server[method](apiUrlWithPrefix, handler);
      } else {
        server[method](apiUrlWithPrefix, isAuthenticated, handler);
      }
    }, toPairs<string, Handler>(handlers));
  }, toPairs<string, { [methodType: string]: Handler; }>(routes));

  // Because of html 5 routing we meed to pass the `index.html` in the case that
  // they directly go to a route (such as `domainName.com/route/<some-param>`)
  // instead of going to `domainName.com`
  server.get('*', (req, res) => {
    res.status(200).sendFile(
      path.resolve(__dirname + '/../../../frontend/dist/index.html')
    );
  });

  return server;
}

/**
 * Initialized express server.
 */
export const server: Express = createExpressServer();
