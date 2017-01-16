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
    | HomeComponentCreateBasicName
    | HomeComponentCreateBasicDescription
    | HomeComponentCreateBasicLanguage
    | HomeComponentCreateBasicTags
    | HomeComponentCreateBasicTidbitIntroduction
    | HomeComponentCreateBasicTidbitFrame Int
    | HomeComponentCreateBasicTidbitConclusion
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
        createBasic =
            create </> s "basic"

        createBasicName =
            createBasic </> s "name"

        createBasicDescription =
            createBasic </> s "description"

        createBasicLanguage =
            createBasic </> s "language"

        createBasicTags =
            createBasic </> s "tags"

        -- Abstract.
        createBasicTidbit =
            createBasic </> s "tidbit"

        createBasicTidbitIntroduction =
            createBasicTidbit </> s "introduction"

        createBasicTidbitFrame =
            createBasicTidbit </> s "frame" </> int

        createBasicTidbitConclusion =
            createBasicTidbit </> s "conclusion"

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
            , map HomeComponentCreateBasicName (createBasicName)
            , map HomeComponentCreateBasicDescription (createBasicDescription)
            , map HomeComponentCreateBasicLanguage (createBasicLanguage)
            , map HomeComponentCreateBasicTags (createBasicTags)
            , map HomeComponentCreateBasicTidbitIntroduction (createBasicTidbitIntroduction)
            , map HomeComponentCreateBasicTidbitFrame (createBasicTidbitFrame)
            , map HomeComponentCreateBasicTidbitConclusion (createBasicTidbitConclusion)
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
    case route of
        HomeComponentBrowse ->
            Config.baseUrl ++ "#"

        HomeComponentCreate ->
            Config.baseUrl ++ "#create"

        HomeComponentCreateBasicName ->
            Config.baseUrl ++ "#create/basic/name"

        HomeComponentCreateBasicDescription ->
            Config.baseUrl ++ "#create/basic/description"

        HomeComponentCreateBasicLanguage ->
            Config.baseUrl ++ "#create/basic/language"

        HomeComponentCreateBasicTags ->
            Config.baseUrl ++ "#create/basic/tags"

        HomeComponentCreateBasicTidbitIntroduction ->
            Config.baseUrl ++ "#create/basic/tidbit/introduction"

        HomeComponentCreateBasicTidbitFrame frameNumber ->
            Config.baseUrl ++ "#create/basic/tidbit/frame/" ++ (toString frameNumber)

        HomeComponentCreateBasicTidbitConclusion ->
            Config.baseUrl ++ "#create/basic/tidbit/conclusion"

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
            let
                failure =
                    Decode.fail <| encodedRouteString ++ " is not a valid route encoding!"
            in
                case encodedRouteString of
                    "HomeComponentBrowse" ->
                        Decode.succeed HomeComponentBrowse

                    "HomeComponentCreate" ->
                        Decode.succeed HomeComponentCreate

                    "HomeComponentCreateBasicName" ->
                        Decode.succeed HomeComponentCreateBasicName

                    "HomeComponentCreateBasicDescription" ->
                        Decode.succeed HomeComponentCreateBasicDescription

                    "HomeComponentCreateBasicLanguage" ->
                        Decode.succeed HomeComponentCreateBasicLanguage

                    "HomeComponentCreateBasicTags" ->
                        Decode.succeed HomeComponentCreateBasicTags

                    "HomeComponentCreateBasicTidbitIntroduction" ->
                        Decode.succeed HomeComponentCreateBasicTidbitIntroduction

                    "HomeComponentCreateBasicTidbitConclusion" ->
                        Decode.succeed HomeComponentCreateBasicTidbitConclusion

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
                            String.startsWith "HomeComponentCreateBasicTidbitFrame "
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
                                            HomeComponentCreateBasicTidbitFrame
                                                frameNumber
                        else
                            failure
    in
        Decode.andThen fromStringDecoder Decode.string
