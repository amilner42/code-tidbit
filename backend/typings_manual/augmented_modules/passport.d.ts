export {};

declare module "passport" {

  function deserializeUser(fn: (id: any, done: (err: any, user?: any, mssg?: Object) => void) => void): void;
  function authenticate(strategy: string, callback: Function): Function;
}
