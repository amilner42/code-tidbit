module Router exposing (navigateTo, parseLocation)

import Models.Route as Route
import Navigation
import UrlParser


{-| Navigates to a given route.
-}
navigateTo : Route.Route -> Cmd msg
navigateTo route =
    Navigation.newUrl <| Route.toUrl <| route


{-| Attempts to parse a location into a route.
-}
parseLocation : Navigation.Location -> Maybe Route.Route
parseLocation location =
    UrlParser.parseHash Route.matchers location
