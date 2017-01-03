module Models.Route
    exposing
        ( Route(..)
        , cacheEncoder
        , cacheDecoder
        , matchers
        , toUrl
        , routesNotNeedingAuth
        , defaultAuthRoute
        , defaultUnauthRoute
        )

import Config
import Json.Decode as Decode
import Json.Encode as Encode
import UrlParser exposing (Parser, s, (</>), oneOf, map, top)


{-| All of the app routes.
-}
type Route
    = HomeComponentBrowse
    | HomeComponentCreate
    | HomeComponentProfile
    | WelcomeComponentLogin
    | WelcomeComponentRegister


{-| For parsing a location (url) into a route.
-}
matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ map HomeComponentBrowse (top)
        , map HomeComponentCreate (s "create")
        , map HomeComponentProfile (s "profile")
        , map WelcomeComponentRegister (s "welcome" </> s "register")
        , map WelcomeComponentLogin (s "welcome" </> s "login")
        ]


{-| All the routes that don't require authentication. By default it will be
assumed all routes require authentication.
-}
routesNotNeedingAuth =
    [ WelcomeComponentLogin
    , WelcomeComponentRegister
    ]


{-| The default route if authenticated.
-}
defaultAuthRoute : Route
defaultAuthRoute =
    HomeComponentBrowse


{-| The default route if unauthenticated.
-}
defaultUnauthRoute : Route
defaultUnauthRoute =
    WelcomeComponentRegister


{-| Converts a route to a url.
-}
toUrl : Route -> String
toUrl route =
    case route of
        HomeComponentBrowse ->
            Config.baseUrl ++ "#"

        HomeComponentCreate ->
            Config.baseUrl ++ "#create"

        HomeComponentProfile ->
            Config.baseUrl ++ "#profile"

        WelcomeComponentLogin ->
            Config.baseUrl ++ "#welcome/login"

        WelcomeComponentRegister ->
            Config.baseUrl ++ "#welcome/register"


{-| The Route `cacheEncoder`.
-}
cacheEncoder : Route -> Encode.Value
cacheEncoder route =
    Encode.string (toString route)


{-| The Route `cacheDecoder`.
-}
cacheDecoder : Decode.Decoder Route
cacheDecoder =
    let
        fromStringDecoder encodedRouteString =
            case encodedRouteString of
                "HomeComponentBrowse" ->
                    Decode.succeed HomeComponentBrowse

                "HomeComponentCreate" ->
                    Decode.succeed HomeComponentCreate

                "HomeComponentProfile" ->
                    Decode.succeed HomeComponentProfile

                "WelcomeComponentLogin" ->
                    Decode.succeed WelcomeComponentLogin

                "WelcomeComponentRegister" ->
                    Decode.succeed WelcomeComponentRegister

                {- Technically string could be anything in local storage, `_` is a
                   wildcard.
                -}
                _ ->
                    Decode.fail <| encodedRouteString ++ " is not a valid route encoding!"
    in
        Decode.andThen fromStringDecoder Decode.string
