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
import UrlParser exposing (Parser, s, (</>), oneOf, map, top, int, string)


{-| For clarity in `Route`.
-}
type alias MongoID =
    String


{-| All of the app routes.
-}
type Route
    = HomeComponentBrowse
    | HomeComponentViewSnipbitIntroduction MongoID
    | HomeComponentViewSnipbitConclusion MongoID
    | HomeComponentViewSnipbitFrame MongoID Int
    | HomeComponentCreate
    | HomeComponentCreateSnipbitName
    | HomeComponentCreateSnipbitDescription
    | HomeComponentCreateSnipbitLanguage
    | HomeComponentCreateSnipbitTags
    | HomeComponentCreateSnipbitCodeIntroduction
    | HomeComponentCreateSnipbitCodeFrame Int
    | HomeComponentCreateSnipbitCodeConclusion
    | HomeComponentCreateBigbitName
    | HomeComponentCreateBigbitDescription
    | HomeComponentCreateBigbitTags
    | HomeComponentCreateBigbitCodeIntroduction
    | HomeComponentCreateBigbitCodeFrame Int
    | HomeComponentCreateBigbitCodeConclusion
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
        view =
            s "view"

        -- Abstract
        viewSnipbit =
            view </> s "snipbit" </> string

        viewSnipbitIntroduction =
            viewSnipbit </> s "introduction"

        viewSnipbitConclusion =
            viewSnipbit </> s "conclusion"

        viewSnipbitFrame =
            viewSnipbit </> s "frame" </> int

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

        -- Abstract.
        createBigbit =
            create </> s "bigbit"

        createBigbitName =
            createBigbit </> s "name"

        createBigbitDescription =
            createBigbit </> s "description"

        createBigbitTags =
            createBigbit </> s "tags"

        -- Abstract.
        createBigbitCode =
            createBigbit </> s "code"

        createBigbitCodeIntroduction =
            createBigbitCode </> s "introduction"

        createBigbitCodeFrame =
            createBigbitCode </> s "frame" </> int

        createBigbitCodeConclusion =
            createBigbitCode </> s "conclusion"

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
            , map HomeComponentViewSnipbitIntroduction (viewSnipbitIntroduction)
            , map HomeComponentViewSnipbitConclusion (viewSnipbitConclusion)
            , map HomeComponentViewSnipbitFrame (viewSnipbitFrame)
            , map HomeComponentCreate (create)
            , map HomeComponentCreateSnipbitName (createSnipbitName)
            , map HomeComponentCreateSnipbitDescription (createSnipbitDescription)
            , map HomeComponentCreateSnipbitLanguage (createSnipbitLanguage)
            , map HomeComponentCreateSnipbitTags (createSnipbitTags)
            , map HomeComponentCreateSnipbitCodeIntroduction (createSnipbitCodeIntroduction)
            , map HomeComponentCreateSnipbitCodeFrame (createSnipbitCodeFrame)
            , map HomeComponentCreateSnipbitCodeConclusion (createSnipbitCodeConclusion)
            , map HomeComponentCreateBigbitName (createBigbitName)
            , map HomeComponentCreateBigbitDescription (createBigbitDescription)
            , map HomeComponentCreateBigbitTags (createBigbitTags)
            , map HomeComponentCreateBigbitCodeIntroduction (createBigbitCodeIntroduction)
            , map HomeComponentCreateBigbitCodeFrame (createBigbitCodeFrame)
            , map HomeComponentCreateBigbitCodeConclusion (createBigbitCodeConclusion)
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
    Config.baseUrl ++ (toHashUrl route)


{-| Converts a route to just the part of the url after (and including) the hash.
-}
toHashUrl : Route -> String
toHashUrl route =
    "#"
        ++ case route of
            HomeComponentBrowse ->
                ""

            HomeComponentCreate ->
                "create"

            HomeComponentViewSnipbitIntroduction mongoID ->
                "view/snipbit/" ++ mongoID ++ "/introduction"

            HomeComponentViewSnipbitConclusion mongoID ->
                "view/snipbit/" ++ mongoID ++ "/conclusion"

            HomeComponentViewSnipbitFrame mongoID frameNumber ->
                "view/snipbit/" ++ mongoID ++ "/frame/" ++ (toString frameNumber)

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

            HomeComponentCreateBigbitName ->
                "create/bigbit/name"

            HomeComponentCreateBigbitDescription ->
                "create/bigbit/description"

            HomeComponentCreateBigbitTags ->
                "create/bigbit/tags"

            HomeComponentCreateBigbitCodeIntroduction ->
                "create/bigbit/code/introduction"

            HomeComponentCreateBigbitCodeFrame frameNumber ->
                "create/bigbit/code/frame/" ++ (toString frameNumber)

            HomeComponentCreateBigbitCodeConclusion ->
                "create/bigbit/code/conclusion"

            HomeComponentProfile ->
                "profile"

            WelcomeComponentLogin ->
                "welcome/login"

            WelcomeComponentRegister ->
                "welcome/register"


{-| The Route `cacheEncoder`.
-}
cacheEncoder : Route -> Encode.Value
cacheEncoder =
    toHashUrl >> Encode.string


{-| The Route `cacheDecoder`.
-}
cacheDecoder : Decode.Decoder Route
cacheDecoder =
    let
        {- Creates a fake location ignoring everything except the hash so we can
           use `parseHash` from the urlParser library to do the route parsing
           for us.
        -}
        fakeLocation hash =
            { href = ""
            , protocol = ""
            , host = ""
            , hostname = ""
            , port_ = ""
            , pathname = ""
            , search = ""
            , hash = hash
            , origin = ""
            , password = ""
            , username = ""
            }

        fromStringDecoder encodedHash =
            let
                maybeRoute =
                    UrlParser.parseHash
                        matchers
                        (fakeLocation encodedHash)
            in
                case maybeRoute of
                    Nothing ->
                        Decode.fail <| encodedHash ++ " is not a valid encoded hash!"

                    Just aRoute ->
                        Decode.succeed aRoute
    in
        Decode.andThen fromStringDecoder Decode.string
