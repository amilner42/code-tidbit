/// <reference path="../typings_manual/index.d.ts" />

import 'babel-polyfill';

import { server } from './server';
import { APP_CONFIG } from './app-config';


server.listen(APP_CONFIG.port);
console.log(`Running app on port ${APP_CONFIG.port}`);
