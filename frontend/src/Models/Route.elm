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
        , navigateTo
        , modifyTo
        , parseLocation
        , navigateToSameUrlWithFilePath
        )

import Config
import DefaultServices.Util as Util
import Json.Decode as Decode
import Json.Encode as Encode
import Elements.FileStructure as FS
import Navigation
import UrlParser exposing (Parser, s, (</>), (<?>), oneOf, map, top, int, string, stringParam)


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
    | HomeComponentViewBigbitIntroduction MongoID (Maybe FS.Path)
    | HomeComponentViewBigbitFrame MongoID Int (Maybe FS.Path)
    | HomeComponentViewBigbitConclusion MongoID (Maybe FS.Path)
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
    | HomeComponentCreateBigbitCodeIntroduction (Maybe FS.Path)
    | HomeComponentCreateBigbitCodeFrame Int (Maybe FS.Path)
    | HomeComponentCreateBigbitCodeConclusion (Maybe FS.Path)
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

        viewBigbit =
            view </> s "bigbit" </> string

        viewBigbitIntroduction =
            viewBigbit </> s "introduction" <?> qpFile

        viewBigbitFrame =
            viewBigbit </> s "frame" </> int <?> qpFile

        viewBigbitConclusion =
            viewBigbit </> s "conclusion" <?> qpFile

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
            (createBigbitCode </> s "introduction") <?> qpFile

        createBigbitCodeFrame =
            createBigbitCode </> s "frame" </> int <?> qpFile

        createBigbitCodeConclusion =
            createBigbitCode </> s "conclusion" <?> qpFile

        -- Query Param for the current active file.
        qpFile =
            stringParam "file"

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
            , map HomeComponentViewBigbitIntroduction (viewBigbitIntroduction)
            , map HomeComponentViewBigbitFrame (viewBigbitFrame)
            , map HomeComponentViewBigbitConclusion (viewBigbitConclusion)
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

            HomeComponentViewBigbitIntroduction mongoID qpFile ->
                "view/bigbit/"
                    ++ mongoID
                    ++ "/introduction/"
                    ++ Util.queryParamsToString [ ( "file", qpFile ) ]

            HomeComponentViewBigbitConclusion mongoID qpFile ->
                "view/bigbit/"
                    ++ mongoID
                    ++ "/conclusion/"
                    ++ Util.queryParamsToString [ ( "file", qpFile ) ]

            HomeComponentViewBigbitFrame mongoID frameNumber qpFile ->
                "view/bigbit/"
                    ++ mongoID
                    ++ "/frame/"
                    ++ (toString frameNumber)
                    ++ "/"
                    ++ Util.queryParamsToString [ ( "file", qpFile ) ]

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

            HomeComponentCreateBigbitCodeIntroduction qpFile ->
                "create/bigbit/code/introduction/"
                    ++ (Util.queryParamsToString [ ( "file", qpFile ) ])

            HomeComponentCreateBigbitCodeFrame frameNumber qpFile ->
                "create/bigbit/code/frame/"
                    ++ (toString frameNumber)
                    ++ "/"
                    ++ (Util.queryParamsToString [ ( "file", qpFile ) ])

            HomeComponentCreateBigbitCodeConclusion qpFile ->
                "create/bigbit/code/conclusion/"
                    ++ (Util.queryParamsToString [ ( "file", qpFile ) ])

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
                    parseLocation <| fakeLocation encodedHash
            in
                case maybeRoute of
                    Nothing ->
                        Decode.fail <| encodedHash ++ " is not a valid encoded hash!"

                    Just aRoute ->
                        Decode.succeed aRoute
    in
        Decode.andThen fromStringDecoder Decode.string


{-| Attempts to parse a location into a route.
-}
parseLocation : Navigation.Location -> Maybe Route
parseLocation location =
    let
        -- @refer https://github.com/evancz/url-parser/issues/27
        fixLocationHashQuery location =
            let
                hash =
                    String.split "?" location.hash
                        |> List.head
                        |> Maybe.withDefault ""

                search =
                    String.split "?" location.hash
                        |> List.drop 1
                        |> String.join "?"
                        |> String.append "?"
            in
                { location | hash = hash, search = search }
    in
        fixLocationHashQuery location
            |> UrlParser.parseHash matchers


{-| Navigates to a given route.
-}
navigateTo : Route -> Cmd msg
navigateTo route =
    Navigation.newUrl <| toUrl <| route


{-| Goes to a given route by modifying the current URL instead of adding a new
url to the browser history.
-}
modifyTo : Route -> Cmd msg
modifyTo route =
    Navigation.modifyUrl <| toUrl <| route


{-| For routes that have a file path query paramter, will  navigate to the same
URL but with the file path added as a query param, otheriwse will do nothing.
-}
navigateToSameUrlWithFilePath : Maybe FS.Path -> Route -> Cmd msg
navigateToSameUrlWithFilePath maybePath route =
    case route of
        HomeComponentViewBigbitIntroduction mongoID _ ->
            navigateTo <| HomeComponentViewBigbitIntroduction mongoID maybePath

        HomeComponentViewBigbitFrame mongoID frameNumber _ ->
            navigateTo <| HomeComponentViewBigbitFrame mongoID frameNumber maybePath

        HomeComponentViewBigbitConclusion mongoID _ ->
            navigateTo <| HomeComponentViewBigbitConclusion mongoID maybePath

        HomeComponentCreateBigbitCodeIntroduction _ ->
            navigateTo <| HomeComponentCreateBigbitCodeIntroduction maybePath

        HomeComponentCreateBigbitCodeFrame frameNumber _ ->
            navigateTo <| HomeComponentCreateBigbitCodeFrame frameNumber maybePath

        HomeComponentCreateBigbitCodeConclusion _ ->
            navigateTo <| HomeComponentCreateBigbitCodeConclusion maybePath

        _ ->
            Cmd.none
