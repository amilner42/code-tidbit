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
import UrlParser exposing (Parser, s, (</>), oneOf, map, top, int)


{-| All of the app routes.
-}
type Route
    = HomeComponentBrowse
    | HomeComponentCreate
    | HomeComponentCreateSnipbitName
    | HomeComponentCreateSnipbitDescription
    | HomeComponentCreateSnipbitLanguage
    | HomeComponentCreateSnipbitTags
    | HomeComponentCreateSnipbitCodeIntroduction
    | HomeComponentCreateSnipbitCodeFrame Int
    | HomeComponentCreateSnipbitCodeConclusion
    | HomeComponentProfile
    | WelcomeComponentLogin
    | WelcomeComponentRegister


{-| For parsing a location (url) into a route.
-}
matchers : Parser (Route -> a) a
matchers =
    let
        create =
            s "create"

        -- Abstract.
        createSnipbit =
            create </> s "snipbit"

        createSnipbitName =
            createSnipbit </> s "name"

        createSnipbitDescription =
            createSnipbit </> s "description"

        createSnipbitLanguage =
            createSnipbit </> s "language"

        createSnipbitTags =
            createSnipbit </> s "tags"

        -- Abstract.
        createSnipbitCode =
            createSnipbit </> s "code"

        createSnipbitCodeIntroduction =
            createSnipbitCode </> s "introduction"

        createSnipbitCodeFrame =
            createSnipbitCode </> s "frame" </> int

        createSnipbitCodeConclusion =
            createSnipbitCode </> s "conclusion"

        profile =
            s "profile"

        -- Abstract.
        welcome =
            s "welcome"

        welcomeRegister =
            welcome </> s "register"

        welcomeLogin =
            welcome </> s "login"
    in
        oneOf
            [ map HomeComponentBrowse (top)
            , map HomeComponentCreate (create)
            , map HomeComponentCreateSnipbitName (createSnipbitName)
            , map HomeComponentCreateSnipbitDescription (createSnipbitDescription)
            , map HomeComponentCreateSnipbitLanguage (createSnipbitLanguage)
            , map HomeComponentCreateSnipbitTags (createSnipbitTags)
            , map HomeComponentCreateSnipbitCodeIntroduction (createSnipbitCodeIntroduction)
            , map HomeComponentCreateSnipbitCodeFrame (createSnipbitCodeFrame)
            , map HomeComponentCreateSnipbitCodeConclusion (createSnipbitCodeConclusion)
            , map HomeComponentProfile (profile)
            , map WelcomeComponentRegister (welcomeRegister)
            , map WelcomeComponentLogin (welcomeLogin)
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
    Config.baseUrl
        ++ "#"
        ++ case route of
            HomeComponentBrowse ->
                ""

            HomeComponentCreate ->
                "create"

            HomeComponentCreateSnipbitName ->
                "create/snipbit/name"

            HomeComponentCreateSnipbitDescription ->
                "create/snipbit/description"

            HomeComponentCreateSnipbitLanguage ->
                "create/snipbit/language"

            HomeComponentCreateSnipbitTags ->
                "create/snipbit/tags"

            HomeComponentCreateSnipbitCodeIntroduction ->
                "create/snipbit/code/introduction"

            HomeComponentCreateSnipbitCodeFrame frameNumber ->
                "create/snipbit/code/frame/" ++ (toString frameNumber)

            HomeComponentCreateSnipbitCodeConclusion ->
                "create/snipbit/code/conclusion"

            HomeComponentProfile ->
                "profile"

            WelcomeComponentLogin ->
                "welcome/login"

            WelcomeComponentRegister ->
                "welcome/register"


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
            let
                failure =
                    Decode.fail <| encodedRouteString ++ " is not a valid route encoding!"
            in
                case encodedRouteString of
                    "HomeComponentBrowse" ->
                        Decode.succeed HomeComponentBrowse

                    "HomeComponentCreate" ->
                        Decode.succeed HomeComponentCreate

                    "HomeComponentCreateSnipbitName" ->
                        Decode.succeed HomeComponentCreateSnipbitName

                    "HomeComponentCreateSnipbitDescription" ->
                        Decode.succeed HomeComponentCreateSnipbitDescription

                    "HomeComponentCreateSnipbitLanguage" ->
                        Decode.succeed HomeComponentCreateSnipbitLanguage

                    "HomeComponentCreateSnipbitTags" ->
                        Decode.succeed HomeComponentCreateSnipbitTags

                    "HomeComponentCreateSnipbitCodeIntroduction" ->
                        Decode.succeed HomeComponentCreateSnipbitCodeIntroduction

                    "HomeComponentCreateSnipbitCodeConclusion" ->
                        Decode.succeed HomeComponentCreateSnipbitCodeConclusion

                    "HomeComponentProfile" ->
                        Decode.succeed HomeComponentProfile

                    "WelcomeComponentLogin" ->
                        Decode.succeed WelcomeComponentLogin

                    "WelcomeComponentRegister" ->
                        Decode.succeed WelcomeComponentRegister

                    {- Here we check if it's any route that had parameters, if not
                       then it's just not a valid route.
                    -}
                    _ ->
                        if
                            String.startsWith "HomeComponentCreateSnipbitCodeFrame "
                                encodedRouteString
                        then
                            let
                                frameNumberAsString =
                                    String.dropLeft 36 encodedRouteString
                            in
                                case String.toInt frameNumberAsString of
                                    Err err ->
                                        failure

                                    Ok frameNumber ->
                                        Decode.succeed <|
                                            HomeComponentCreateSnipbitCodeFrame
                                                frameNumber
                        else
                            failure
    in
        Decode.andThen fromStringDecoder Decode.string
