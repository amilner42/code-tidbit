/// Module for setting up the express server (all middleware).

import bodyParser from 'body-parser';
import express, { Express, Handler, Response } from 'express';
import expressSession from 'express-session';
import sessionStore from 'connect-mongo';
import path from 'path';
import { toPairs, contains, map }   from 'ramda';
import passport from 'passport';
import * as kleen from "kleen";

import { APP_CONFIG } from './app-config';
import { toMongoObjectID, collection } from './db';
import { loginStrategy, signUpStrategy } from './passport-local-auth-strategies';
import { internalError } from './util';
import { authlessRoutes, routes } from './routes';
import { FrontendError, RouteHandler } from './types';


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
 * Use in catch-blocks (eg. `.catch(handleError(res))`) to check and then send
 * outgoing errors. Will make sure all outgoing errors have the `FrontendError`
 * format.
 */
const handleError = (res: Response): ((error: FrontendError) => Promise<void>) => {
  // Kleen schema for a FrontendError.
  const frontendErrorScheme: kleen.typeSchema = {
    objectProperties: {
        "errorCode": {
            primitiveType: kleen.kindOfPrimitive.number
        },
        "message": {
            primitiveType: kleen.kindOfPrimitive.string
        },
    }
  };

  return (error) => {
    return kleen.validModel(frontendErrorScheme)(error)
    .then(() => {
      res.status(400).json(error);
    })
    .catch(() => {
      console.log("[LOG] Unknown error: " + error);

      res.status(400).json(
        internalError("An unknown internal error occured...")
      );
    });
  };
};

/**
 * Sends the success object back to the server with a 200 status.
 */
const handleSuccess =  (res: Response): ((successObj) => void) => {
  return (successObj) => {
    res.status(200).json(successObj);
  }
};

/**
 * Converts our internal `RouteHandler` into an express `Handler`.
 *
 * Handles an action where we want to send the result object back to the server
 * directly upon success (status 200) and we want to send a proper error message
 * back to the server upon failure (status 400).
 */
const wrapRouteHandler = (routeHandler: RouteHandler): Handler => {
  return (req, res, next) => {
    routeHandler(req, res, next)
    .then(handleSuccess(res))
    .catch(handleError(res));
  }
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

  // Set up passport middleware.
  setUpPassport();

  // Add all API routes.
  map(([apiUrl, handlers]) => {
    const apiUrlWithPrefix = '/api' + apiUrl;

    map(([method, handler]: [string, any]) => {
      if(authlessRoutes[apiUrl] && authlessRoutes[apiUrl][method]) {
        server[method](apiUrlWithPrefix, wrapRouteHandler(handler));
      } else {
        server[method](apiUrlWithPrefix, isAuthenticated, wrapRouteHandler(handler));
      }
    }, toPairs<string, Handler>(handlers));
  }, toPairs<string, { [methodType: string]: Handler; }>(routes));

  // This should be after `server.use(expressSession...`, or too many sessions may be created! This should also be
  // after adding all the API routes.
  if(APP_CONFIG.mode === "dev") {
    console.log("Serving frontend through the backend...");
    server.use(express.static('./frontend/dist'));
    // If it's in `dev` mode then we just serve the files directly by the backend.
    // Because of html 5 routing we meed to pass the `index.html` in the case that
    // they directly go to a route (such as `domainName.com/route/<some-param>`)
    // instead of going to `domainName.com`
    server.get('*', (req, res) => {
      res.status(200).sendFile(
        path.resolve(__dirname + '/../../../frontend/dist/index.html')
      );
    });
  }

  return server;
}

/**
 * Initialized express server.
 */
export const server: Express = createExpressServer();
