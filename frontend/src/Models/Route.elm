module Models.Route exposing (..)

import Array
import DefaultServices.Util as Util
import Elements.FileStructure as FS
import Models.Bigbit as Bigbit
import Navigation
import UrlParser exposing (Parser, s, (</>), (<?>), oneOf, map, top, int, string, stringParam)


{-| For clarity in `Route`.
-}
type alias MongoID =
    String


{-| All of the app routes.
-}
type Route
    = BrowsePage
    | ViewSnipbitIntroductionPage (Maybe MongoID) MongoID
    | ViewSnipbitConclusionPage (Maybe MongoID) MongoID
    | ViewSnipbitFramePage (Maybe MongoID) MongoID Int
    | ViewBigbitIntroductionPage (Maybe MongoID) MongoID (Maybe FS.Path)
    | ViewBigbitFramePage (Maybe MongoID) MongoID Int (Maybe FS.Path)
    | ViewBigbitConclusionPage (Maybe MongoID) MongoID (Maybe FS.Path)
    | ViewStoryPage MongoID
    | CreatePage
    | CreateSnipbitNamePage
    | CreateSnipbitDescriptionPage
    | CreateSnipbitLanguagePage
    | CreateSnipbitTagsPage
    | CreateSnipbitCodeIntroductionPage
    | CreateSnipbitCodeFramePage Int
    | CreateSnipbitCodeConclusionPage
    | CreateBigbitNamePage
    | CreateBigbitDescriptionPage
    | CreateBigbitTagsPage
    | CreateBigbitCodeIntroductionPage (Maybe FS.Path)
    | CreateBigbitCodeFramePage Int (Maybe FS.Path)
    | CreateBigbitCodeConclusionPage (Maybe FS.Path)
    | CreateStoryNamePage (Maybe MongoID)
    | CreateStoryDescriptionPage (Maybe MongoID)
    | CreateStoryTagsPage (Maybe MongoID)
    | DevelopStoryPage MongoID
    | ProfilePage
    | LoginPage
    | RegisterPage


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
            view </> s "snipbit" <?> qpFromStory </> string

        viewSnipbitIntroduction =
            viewSnipbit </> s "introduction"

        viewSnipbitConclusion =
            viewSnipbit </> s "conclusion"

        viewSnipbitFrame =
            viewSnipbit </> s "frame" </> int

        viewBigbit =
            view </> s "bigbit" <?> qpFromStory </> string

        viewBigbitIntroduction =
            viewBigbit </> s "introduction" <?> qpFile

        viewBigbitFrame =
            viewBigbit </> s "frame" </> int <?> qpFile

        viewBigbitConclusion =
            viewBigbit </> s "conclusion" <?> qpFile

        viewStory =
            view </> s "story" </> string

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

        createStory =
            create </> s "story"

        createStoryName =
            createStory </> s "name" <?> qpEditingStory

        createStoryDescription =
            createStory </> s "description" <?> qpEditingStory

        createStoryTags =
            createStory </> s "tags" <?> qpEditingStory

        developStory =
            s "develop" </> s "story" </> string

        qpEditingStory =
            stringParam "editingStory"

        qpFile =
            stringParam "file"

        qpFromStory =
            stringParam "fromStory"

        profile =
            s "profile"

        register =
            s "register"

        login =
            s "login"
    in
        oneOf
            [ map BrowsePage top
            , map ViewSnipbitIntroductionPage viewSnipbitIntroduction
            , map ViewSnipbitConclusionPage viewSnipbitConclusion
            , map ViewSnipbitFramePage viewSnipbitFrame
            , map ViewBigbitIntroductionPage viewBigbitIntroduction
            , map ViewBigbitFramePage viewBigbitFrame
            , map ViewBigbitConclusionPage viewBigbitConclusion
            , map ViewStoryPage viewStory
            , map CreatePage create
            , map CreateSnipbitNamePage createSnipbitName
            , map CreateSnipbitDescriptionPage createSnipbitDescription
            , map CreateSnipbitLanguagePage createSnipbitLanguage
            , map CreateSnipbitTagsPage createSnipbitTags
            , map CreateSnipbitCodeIntroductionPage createSnipbitCodeIntroduction
            , map CreateSnipbitCodeFramePage createSnipbitCodeFrame
            , map CreateSnipbitCodeConclusionPage createSnipbitCodeConclusion
            , map CreateBigbitNamePage createBigbitName
            , map CreateBigbitDescriptionPage createBigbitDescription
            , map CreateBigbitTagsPage createBigbitTags
            , map CreateBigbitCodeIntroductionPage createBigbitCodeIntroduction
            , map CreateBigbitCodeFramePage createBigbitCodeFrame
            , map CreateBigbitCodeConclusionPage createBigbitCodeConclusion
            , map CreateStoryNamePage createStoryName
            , map CreateStoryDescriptionPage createStoryDescription
            , map CreateStoryTagsPage createStoryTags
            , map DevelopStoryPage developStory
            , map ProfilePage profile
            , map RegisterPage register
            , map LoginPage login
            ]


{-| Returns `True` iff the route requires authentication.
-}
routeRequiresAuth : Route -> Bool
routeRequiresAuth route =
    case route of
        LoginPage ->
            False

        RegisterPage ->
            False

        ViewSnipbitIntroductionPage _ _ ->
            False

        ViewSnipbitFramePage _ _ _ ->
            False

        ViewSnipbitConclusionPage _ _ ->
            False

        ViewBigbitIntroductionPage _ _ _ ->
            False

        ViewBigbitFramePage _ _ _ _ ->
            False

        ViewBigbitConclusionPage _ _ _ ->
            False

        ViewStoryPage _ ->
            False

        BrowsePage ->
            False

        _ ->
            True


{-| Returns `True` iff the route requires that the user not be authenticated.

NOTE: This is NOT the same as `not routeRequiresAuth` as there are routes
that the user can access both logged-in and logged-out, these are specifically
the routes that you must be logged-out to access.
-}
routeRequiresNotAuth : Route -> Bool
routeRequiresNotAuth route =
    case route of
        LoginPage ->
            True

        RegisterPage ->
            True

        _ ->
            False


{-| The default route if authenticated.
-}
defaultAuthRoute : Route
defaultAuthRoute =
    BrowsePage


{-| The default route if unauthenticated.
-}
defaultUnauthRoute : Route
defaultUnauthRoute =
    RegisterPage


{-| Converts a route to just the part of the url after (and including) the hash.
-}
toHashUrl : Route -> String
toHashUrl route =
    "#"
        ++ case route of
            BrowsePage ->
                ""

            CreatePage ->
                "create"

            ViewSnipbitIntroductionPage qpStoryID mongoID ->
                "view/snipbit/"
                    ++ mongoID
                    ++ "/introduction"
                    ++ Util.queryParamsToString [ ( "fromStory", qpStoryID ) ]

            ViewSnipbitConclusionPage qpStoryID mongoID ->
                "view/snipbit/"
                    ++ mongoID
                    ++ "/conclusion"
                    ++ Util.queryParamsToString [ ( "fromStory", qpStoryID ) ]

            ViewSnipbitFramePage qpStoryID mongoID frameNumber ->
                "view/snipbit/"
                    ++ mongoID
                    ++ "/frame/"
                    ++ (toString frameNumber)
                    ++ Util.queryParamsToString [ ( "fromStory", qpStoryID ) ]

            ViewBigbitIntroductionPage qpStoryID mongoID qpFile ->
                "view/bigbit/"
                    ++ mongoID
                    ++ "/introduction/"
                    ++ Util.queryParamsToString [ ( "file", qpFile ), ( "fromStory", qpStoryID ) ]

            ViewBigbitConclusionPage qpStoryID mongoID qpFile ->
                "view/bigbit/"
                    ++ mongoID
                    ++ "/conclusion/"
                    ++ Util.queryParamsToString [ ( "file", qpFile ), ( "fromStory", qpStoryID ) ]

            ViewBigbitFramePage qpStoryID mongoID frameNumber qpFile ->
                "view/bigbit/"
                    ++ mongoID
                    ++ "/frame/"
                    ++ (toString frameNumber)
                    ++ "/"
                    ++ Util.queryParamsToString [ ( "file", qpFile ), ( "fromStory", qpStoryID ) ]

            ViewStoryPage mongoID ->
                "view/story/" ++ mongoID

            CreateSnipbitNamePage ->
                "create/snipbit/name"

            CreateSnipbitDescriptionPage ->
                "create/snipbit/description"

            CreateSnipbitLanguagePage ->
                "create/snipbit/language"

            CreateSnipbitTagsPage ->
                "create/snipbit/tags"

            CreateSnipbitCodeIntroductionPage ->
                "create/snipbit/code/introduction"

            CreateSnipbitCodeFramePage frameNumber ->
                "create/snipbit/code/frame/" ++ (toString frameNumber)

            CreateSnipbitCodeConclusionPage ->
                "create/snipbit/code/conclusion"

            CreateBigbitNamePage ->
                "create/bigbit/name"

            CreateBigbitDescriptionPage ->
                "create/bigbit/description"

            CreateBigbitTagsPage ->
                "create/bigbit/tags"

            CreateBigbitCodeIntroductionPage qpFile ->
                "create/bigbit/code/introduction/"
                    ++ (Util.queryParamsToString [ ( "file", qpFile ) ])

            CreateBigbitCodeFramePage frameNumber qpFile ->
                "create/bigbit/code/frame/"
                    ++ (toString frameNumber)
                    ++ "/"
                    ++ (Util.queryParamsToString [ ( "file", qpFile ) ])

            CreateBigbitCodeConclusionPage qpFile ->
                "create/bigbit/code/conclusion/"
                    ++ (Util.queryParamsToString [ ( "file", qpFile ) ])

            CreateStoryNamePage qpStory ->
                "create/story/name"
                    ++ (Util.queryParamsToString [ ( "editingStory", qpStory ) ])

            CreateStoryDescriptionPage qpStory ->
                "create/story/description"
                    ++ (Util.queryParamsToString [ ( "editingStory", qpStory ) ])

            CreateStoryTagsPage qpStory ->
                "create/story/tags"
                    ++ (Util.queryParamsToString [ ( "editingStory", qpStory ) ])

            DevelopStoryPage storyID ->
                "develop/story/" ++ storyID

            ProfilePage ->
                "profile"

            LoginPage ->
                "login"

            RegisterPage ->
                "register"


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
    Navigation.newUrl <| toHashUrl <| route


{-| Goes to a given route by modifying the current URL instead of adding a new
url to the browser history.
-}
modifyTo : Route -> Cmd msg
modifyTo route =
    Navigation.modifyUrl <| toHashUrl <| route


{-| For routes that have a file path query paramter, will  navigate to the same
URL but with the file path added as a query param, otheriwse will do nothing.
-}
navigateToSameUrlWithFilePath : Maybe FS.Path -> Route -> Cmd msg
navigateToSameUrlWithFilePath maybePath route =
    case route of
        ViewBigbitIntroductionPage fromStoryID mongoID _ ->
            navigateTo <| ViewBigbitIntroductionPage fromStoryID mongoID maybePath

        ViewBigbitFramePage fromStoryID mongoID frameNumber _ ->
            navigateTo <| ViewBigbitFramePage fromStoryID mongoID frameNumber maybePath

        ViewBigbitConclusionPage fromStoryID mongoID _ ->
            navigateTo <| ViewBigbitConclusionPage fromStoryID mongoID maybePath

        CreateBigbitCodeIntroductionPage _ ->
            navigateTo <| CreateBigbitCodeIntroductionPage maybePath

        CreateBigbitCodeFramePage frameNumber _ ->
            navigateTo <| CreateBigbitCodeFramePage frameNumber maybePath

        CreateBigbitCodeConclusionPage _ ->
            navigateTo <| CreateBigbitCodeConclusionPage maybePath

        _ ->
            Cmd.none


{-| Returns the query paramater "editingStory" if on the create new story routes
and the parameter is present.
-}
getEditingStoryQueryParamOnCreateNewStoryRoute : Route -> Maybe MongoID
getEditingStoryQueryParamOnCreateNewStoryRoute route =
    case route of
        CreateStoryNamePage qpEditingStory ->
            qpEditingStory

        CreateStoryDescriptionPage qpEditingStory ->
            qpEditingStory

        CreateStoryTagsPage qpEditingStory ->
            qpEditingStory

        _ ->
            Nothing


{-| Returns the query parameter "fromStory" if viewing a snipbit and that query
param is present.
-}
getFromStoryQueryParamOnViewSnipbitRoute : Route -> Maybe MongoID
getFromStoryQueryParamOnViewSnipbitRoute route =
    case route of
        ViewSnipbitIntroductionPage fromStoryID _ ->
            fromStoryID

        ViewSnipbitFramePage fromStoryID _ _ ->
            fromStoryID

        ViewSnipbitConclusionPage fromStoryID _ ->
            fromStoryID

        _ ->
            Nothing


{-| Returns the query parameter "fromStory" if viewing a bigbit and that query
param is present.
-}
getFromStoryQueryParamOnViewBigbitRoute : Route -> Maybe MongoID
getFromStoryQueryParamOnViewBigbitRoute route =
    case route of
        ViewBigbitIntroductionPage fromStoryID _ _ ->
            fromStoryID

        ViewBigbitFramePage fromStoryID _ _ _ ->
            fromStoryID

        ViewBigbitConclusionPage fromStoryID _ _ ->
            fromStoryID

        _ ->
            Nothing


{-| The current active path determined from the route.
-}
createBigbitPageCurrentActiveFile : Route -> Maybe FS.Path
createBigbitPageCurrentActiveFile route =
    case route of
        CreateBigbitCodeIntroductionPage maybePath ->
            maybePath

        CreateBigbitCodeFramePage _ maybePath ->
            maybePath

        CreateBigbitCodeConclusionPage maybePath ->
            maybePath

        _ ->
            Nothing


{-| The current active path determined from the route and the current comment frame.
-}
viewBigbitPageCurrentActiveFile : Route -> Bigbit.Bigbit -> Maybe FS.Path
viewBigbitPageCurrentActiveFile route bigbit =
    case route of
        ViewBigbitIntroductionPage _ _ maybePath ->
            maybePath

        ViewBigbitFramePage _ _ frameNumber maybePath ->
            if Util.isNotNothing maybePath then
                maybePath
            else
                Array.get (frameNumber - 1) bigbit.highlightedComments
                    |> Maybe.map .file

        ViewBigbitConclusionPage _ _ maybePath ->
            maybePath

        _ ->
            Nothing
