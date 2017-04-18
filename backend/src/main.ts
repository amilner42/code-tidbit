/// <reference path="../typings_manual/index.d.ts" />

import 'babel-polyfill';

import { server } from './server';
import { APP_CONFIG } from './app-config';


server.listen(APP_CONFIG.port);
console.log(`Running API on port ${APP_CONFIG.port} in ${APP_CONFIG.mode.toUpperCase()} mode`);
