module Models.Route exposing (..)

import Array
import DefaultServices.Editable as Editable
import DefaultServices.InfixFunctions exposing (..)
import DefaultServices.Util as Util
import Elements.Simple.FileStructure as FS
import Models.Bigbit as Bigbit
import Models.QA as QA
import Navigation
import ProjectTypeAliases exposing (..)
import UrlParser exposing (Parser, s, (</>), (<?>), oneOf, map, top, int, string, stringParam)


{-| All of the app routes.

NOTE: When creating routes, use type aliases to make sure that the purpose of each parameter is clear (eg. StoryID).
-}
type Route
    = BrowsePage
    | ViewSnipbitIntroductionPage (Maybe StoryID) SnipbitID
    | ViewSnipbitConclusionPage (Maybe StoryID) SnipbitID
    | ViewSnipbitFramePage (Maybe StoryID) SnipbitID FrameNumber
    | ViewSnipbitQuestionsPage (Maybe StoryID) SnipbitID
    | ViewSnipbitQuestionPage (Maybe StoryID) (Maybe MeaninglessString) SnipbitID QuestionID
    | ViewSnipbitAnswersPage (Maybe StoryID) (Maybe MeaninglessString) SnipbitID QuestionID
    | ViewSnipbitAnswerPage (Maybe StoryID) (Maybe MeaninglessString) SnipbitID AnswerID
    | ViewSnipbitQuestionCommentsPage (Maybe StoryID) (Maybe MeaninglessString) SnipbitID QuestionID (Maybe CommentID)
    | ViewSnipbitAnswerCommentsPage (Maybe StoryID) (Maybe MeaninglessString) SnipbitID AnswerID (Maybe CommentID)
    | ViewSnipbitAskQuestion (Maybe StoryID) SnipbitID
    | ViewSnipbitAnswerQuestion (Maybe StoryID) SnipbitID QuestionID
    | ViewSnipbitEditQuestion (Maybe StoryID) SnipbitID QuestionID
    | ViewSnipbitEditAnswer (Maybe StoryID) SnipbitID AnswerID
    | ViewBigbitIntroductionPage (Maybe StoryID) BigbitID (Maybe FS.Path)
    | ViewBigbitFramePage (Maybe StoryID) BigbitID FrameNumber (Maybe FS.Path)
    | ViewBigbitConclusionPage (Maybe StoryID) BigbitID (Maybe FS.Path)
    | ViewBigbitQuestionsPage (Maybe StoryID) BigbitID
    | ViewBigbitQuestionPage (Maybe StoryID) (Maybe MeaninglessString) BigbitID QuestionID
    | ViewBigbitAnswersPage (Maybe StoryID) (Maybe MeaninglessString) BigbitID QuestionID
    | ViewBigbitAnswerPage (Maybe StoryID) (Maybe MeaninglessString) BigbitID AnswerID
    | ViewBigbitQuestionCommentsPage (Maybe StoryID) (Maybe MeaninglessString) BigbitID QuestionID (Maybe CommentID)
    | ViewBigbitAnswerCommentsPage (Maybe StoryID) (Maybe MeaninglessString) BigbitID AnswerID (Maybe CommentID)
    | ViewBigbitAskQuestion (Maybe StoryID) BigbitID
    | ViewBigbitEditQuestion (Maybe StoryID) BigbitID QuestionID
    | ViewBigbitAnswerQuestion (Maybe StoryID) BigbitID QuestionID
    | ViewBigbitEditAnswer (Maybe StoryID) BigbitID AnswerID
    | ViewStoryPage StoryID
    | CreatePage
    | CreateSnipbitNamePage
    | CreateSnipbitDescriptionPage
    | CreateSnipbitLanguagePage
    | CreateSnipbitTagsPage
    | CreateSnipbitCodeIntroductionPage
    | CreateSnipbitCodeFramePage FrameNumber
    | CreateSnipbitCodeConclusionPage
    | CreateBigbitNamePage
    | CreateBigbitDescriptionPage
    | CreateBigbitTagsPage
    | CreateBigbitCodeIntroductionPage (Maybe FS.Path)
    | CreateBigbitCodeFramePage FrameNumber (Maybe FS.Path)
    | CreateBigbitCodeConclusionPage (Maybe FS.Path)
    | CreateStoryNamePage (Maybe EditingStoryID)
    | CreateStoryDescriptionPage (Maybe EditingStoryID)
    | CreateStoryTagsPage (Maybe EditingStoryID)
    | DevelopStoryPage StoryID
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

        -- Abstract
        viewSnipbitTouringQuestions =
            view </> s "snipbit" <?> qpFromStory <?> qpTouringQuestions </> string

        viewSnipbitIntroduction =
            viewSnipbit </> s "introduction"

        viewSnipbitConclusion =
            viewSnipbit </> s "conclusion"

        viewSnipbitFrame =
            viewSnipbit </> s "frame" </> int

        viewSnipbitQuestionsPage =
            viewSnipbit </> s "questions"

        viewSnipbitQuestionPage =
            viewSnipbitTouringQuestions </> s "question" </> string

        viewSnipbitAnswersPage =
            viewSnipbitQuestionPage </> s "answers"

        viewSnipbitAnswerPage =
            viewSnipbitTouringQuestions </> s "answer" </> string

        viewSnipbitQuestionCommentsPage =
            viewSnipbitQuestionPage </> s "comments" <?> qpCommentID

        viewSnipbitAnswerCommentsPage =
            viewSnipbitAnswerPage </> s "comments" <?> qpCommentID

        viewSnipbitAskQuestion =
            viewSnipbit </> s "askQuestion"

        viewSnipbitAnswerQuestion =
            viewSnipbit </> s "answerQuestion" </> string

        viewSnipbitEditQuestion =
            viewSnipbit </> s "editQuestion" </> string

        viewSnipbitEditAnswer =
            viewSnipbit </> s "editAnswer" </> string

        -- Abstract.
        viewBigbit =
            view </> s "bigbit" <?> qpFromStory </> string

        -- Abstract.
        viewBigbitTouringQuestions =
            view </> s "bigbit" <?> qpFromStory <?> qpTouringQuestions </> string

        viewBigbitIntroduction =
            viewBigbit </> s "introduction" <?> qpFile

        viewBigbitFrame =
            viewBigbit </> s "frame" </> int <?> qpFile

        viewBigbitConclusion =
            viewBigbit </> s "conclusion" <?> qpFile

        viewBigbitQuestionsPage =
            viewBigbit </> s "questions"

        viewBigbitQuestionPage =
            viewBigbitTouringQuestions </> s "question" </> string

        viewBigbitAnswersPage =
            viewBigbitQuestionPage </> s "answers"

        viewBigbitAnswerPage =
            viewBigbitTouringQuestions </> s "answer" </> string

        viewBigbitQuestionCommentsPage =
            viewBigbitQuestionPage </> s "comments" <?> qpCommentID

        viewBigbitAnswerCommentsPage =
            viewBigbitAnswerPage </> s "comments" <?> qpCommentID

        viewBigbitAskQuestion =
            viewBigbit </> s "askQuestion"

        viewBigbitEditQuestion =
            viewBigbit </> s "editQuestion" </> string

        viewBigbitAnswerQuestion =
            viewBigbit </> s "answerQuestion" </> string

        viewBigbitEditAnswer =
            viewBigbit </> s "editAnswer" </> string

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

        qpCommentID =
            stringParam "commentID"

        qpTouringQuestions =
            stringParam "touringQuestions"

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
            , map ViewSnipbitQuestionsPage viewSnipbitQuestionsPage
            , map ViewSnipbitQuestionPage viewSnipbitQuestionPage
            , map ViewSnipbitAnswersPage viewSnipbitAnswersPage
            , map ViewSnipbitAnswerPage viewSnipbitAnswerPage
            , map ViewSnipbitQuestionCommentsPage viewSnipbitQuestionCommentsPage
            , map ViewSnipbitAnswerCommentsPage viewSnipbitAnswerCommentsPage
            , map ViewSnipbitAskQuestion viewSnipbitAskQuestion
            , map ViewSnipbitAnswerQuestion viewSnipbitAnswerQuestion
            , map ViewSnipbitEditQuestion viewSnipbitEditQuestion
            , map ViewSnipbitEditAnswer viewSnipbitEditAnswer
            , map ViewBigbitIntroductionPage viewBigbitIntroduction
            , map ViewBigbitFramePage viewBigbitFrame
            , map ViewBigbitConclusionPage viewBigbitConclusion
            , map ViewBigbitQuestionsPage viewBigbitQuestionsPage
            , map ViewBigbitQuestionPage viewBigbitQuestionPage
            , map ViewBigbitAnswersPage viewBigbitAnswersPage
            , map ViewBigbitAnswerPage viewBigbitAnswerPage
            , map ViewBigbitQuestionCommentsPage viewBigbitQuestionCommentsPage
            , map ViewBigbitAnswerCommentsPage viewBigbitAnswerCommentsPage
            , map ViewBigbitAskQuestion viewBigbitAskQuestion
            , map ViewBigbitEditQuestion viewBigbitEditQuestion
            , map ViewBigbitAnswerQuestion viewBigbitAnswerQuestion
            , map ViewBigbitEditAnswer viewBigbitEditAnswer
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

        ViewSnipbitQuestionsPage _ _ ->
            False

        ViewSnipbitQuestionPage _ _ _ _ ->
            False

        ViewSnipbitAnswersPage _ _ _ _ ->
            False

        ViewSnipbitAnswerPage _ _ _ _ ->
            False

        ViewSnipbitQuestionCommentsPage _ _ _ _ _ ->
            False

        ViewSnipbitAnswerCommentsPage _ _ _ _ _ ->
            False

        ViewBigbitIntroductionPage _ _ _ ->
            False

        ViewBigbitFramePage _ _ _ _ ->
            False

        ViewBigbitConclusionPage _ _ _ ->
            False

        ViewBigbitQuestionsPage _ _ ->
            False

        ViewBigbitQuestionPage _ _ _ _ ->
            False

        ViewBigbitAnswersPage _ _ _ _ ->
            False

        ViewBigbitAnswerPage _ _ _ _ ->
            False

        ViewBigbitQuestionCommentsPage _ _ _ _ _ ->
            False

        ViewBigbitAnswerCommentsPage _ _ _ _ _ ->
            False

        ViewStoryPage _ ->
            False

        BrowsePage ->
            False

        _ ->
            True


{-| Returns `True` iff the route requires that the user not be authenticated.

NOTE: This is NOT the same as `not routeRequiresAuth` as there are routes that the user can access both logged-in and
      logged-out, these are specifically the routes that you must be logged-out to access.
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

            ViewSnipbitQuestionsPage qpStoryID snipbitID ->
                "view/snipbit/"
                    ++ snipbitID
                    ++ "/questions"
                    ++ Util.queryParamsToString [ ( "fromStory", qpStoryID ) ]

            ViewSnipbitQuestionPage qpStoryID qpTouringQuestions snipbitID questionID ->
                "view/snipbit/"
                    ++ snipbitID
                    ++ "/question/"
                    ++ questionID
                    ++ Util.queryParamsToString
                        [ ( "fromStory", qpStoryID ), ( "touringQuestions", qpTouringQuestions ) ]

            ViewSnipbitAnswersPage qpStoryID qpTouringQuestions snipbitID questionID ->
                "view/snipbit/"
                    ++ snipbitID
                    ++ "/question/"
                    ++ questionID
                    ++ "/answers"
                    ++ Util.queryParamsToString
                        [ ( "fromStory", qpStoryID ), ( "touringQuestions", qpTouringQuestions ) ]

            ViewSnipbitAnswerPage qpStoryID qpTouringQuestions snipbitID answerID ->
                "view/snipbit/"
                    ++ snipbitID
                    ++ "/answer/"
                    ++ answerID
                    ++ Util.queryParamsToString
                        [ ( "fromStory", qpStoryID ), ( "touringQuestions", qpTouringQuestions ) ]

            ViewSnipbitQuestionCommentsPage qpStoryID qpTouringQuestions snipbitID questionID qpCommentID ->
                "view/snipbit/"
                    ++ snipbitID
                    ++ "/question/"
                    ++ questionID
                    ++ "/comments"
                    ++ Util.queryParamsToString
                        [ ( "fromStory", qpStoryID )
                        , ( "commentID", qpCommentID )
                        , ( "touringQuestions", qpTouringQuestions )
                        ]

            ViewSnipbitAnswerCommentsPage qpStoryID qpTouringQuestions snipbitID answerID qpCommentID ->
                "view/snipbit/"
                    ++ snipbitID
                    ++ "/answer/"
                    ++ answerID
                    ++ "/comments"
                    ++ Util.queryParamsToString
                        [ ( "fromStory", qpStoryID )
                        , ( "commentID", qpCommentID )
                        , ( "touringQuestions", qpTouringQuestions )
                        ]

            ViewSnipbitAskQuestion qpStoryID snipbitID ->
                "view/snipbit/"
                    ++ snipbitID
                    ++ "/askQuestion"
                    ++ Util.queryParamsToString [ ( "fromStory", qpStoryID ) ]

            ViewSnipbitAnswerQuestion qpStoryID snipbitID questionID ->
                "view/snipbit/"
                    ++ snipbitID
                    ++ "/answerQuestion/"
                    ++ questionID
                    ++ Util.queryParamsToString [ ( "fromStory", qpStoryID ) ]

            ViewSnipbitEditQuestion qpStoryID snipbitID questionID ->
                "view/snipbit/"
                    ++ snipbitID
                    ++ "/editQuestion/"
                    ++ questionID
                    ++ Util.queryParamsToString [ ( "fromStory", qpStoryID ) ]

            ViewSnipbitEditAnswer qpStoryID snipbitID answerID ->
                "view/snipbit/"
                    ++ snipbitID
                    ++ "/editAnswer/"
                    ++ answerID
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

            ViewBigbitQuestionsPage qpStoryID bigbitID ->
                "view/bigbit/"
                    ++ bigbitID
                    ++ "/questions"
                    ++ Util.queryParamsToString [ ( "fromStory", qpStoryID ) ]

            ViewBigbitQuestionPage qpStoryID qpTouringQuestions bigbitID questionID ->
                "view/bigbit/"
                    ++ bigbitID
                    ++ "/question/"
                    ++ questionID
                    ++ Util.queryParamsToString
                        [ ( "fromStory", qpStoryID ), ( "touringQuestions", qpTouringQuestions ) ]

            ViewBigbitAnswersPage qpStoryID qpTouringQuestions bigbitID questionID ->
                "view/bigbit/"
                    ++ bigbitID
                    ++ "/question/"
                    ++ questionID
                    ++ "/answers"
                    ++ Util.queryParamsToString
                        [ ( "fromStory", qpStoryID ), ( "touringQuestions", qpTouringQuestions ) ]

            ViewBigbitAnswerPage qpStoryID qpTouringQuestions bigbitID answerID ->
                "view/bigbit/"
                    ++ bigbitID
                    ++ "/answer/"
                    ++ answerID
                    ++ Util.queryParamsToString
                        [ ( "fromStory", qpStoryID ), ( "touringQuestions", qpTouringQuestions ) ]

            ViewBigbitQuestionCommentsPage qpStoryID qpTouringQuestions bigbitID questionID qpCommentID ->
                "view/bigbit/"
                    ++ bigbitID
                    ++ "/question/"
                    ++ questionID
                    ++ "/comments"
                    ++ Util.queryParamsToString
                        [ ( "fromStory", qpStoryID )
                        , ( "touringQuestions", qpTouringQuestions )
                        , ( "commentID", qpCommentID )
                        ]

            ViewBigbitAnswerCommentsPage qpStoryID qpTouringQuestions bigbitID answerID qpCommentID ->
                "view/bigbit/"
                    ++ bigbitID
                    ++ "/answer/"
                    ++ answerID
                    ++ "/comments"
                    ++ Util.queryParamsToString
                        [ ( "fromStory", qpStoryID )
                        , ( "touringQuestions", qpTouringQuestions )
                        , ( "commentID", qpCommentID )
                        ]

            ViewBigbitAskQuestion qpStoryID bigbitID ->
                "view/bigbit/"
                    ++ bigbitID
                    ++ "/askQuestion"
                    ++ Util.queryParamsToString [ ( "fromStory", qpStoryID ) ]

            ViewBigbitEditQuestion qpStoryID bigbitID questionID ->
                "view/bigbit/"
                    ++ bigbitID
                    ++ "/editQuestion/"
                    ++ questionID
                    ++ Util.queryParamsToString [ ( "fromStory", qpStoryID ) ]

            ViewBigbitAnswerQuestion qpStoryID bigbitID questionID ->
                "view/bigbit/"
                    ++ bigbitID
                    ++ "/answerQuestion/"
                    ++ questionID
                    ++ Util.queryParamsToString [ ( "fromStory", qpStoryID ) ]

            ViewBigbitEditAnswer qpStoryID bigbitID answerID ->
                "view/bigbit/"
                    ++ bigbitID
                    ++ "/editAnswer/"
                    ++ answerID
                    ++ Util.queryParamsToString [ ( "fromStory", qpStoryID ) ]

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


{-| Goes to a given route by modifying the current URL instead of adding a new url to the browser history.
-}
modifyTo : Route -> Cmd msg
modifyTo route =
    Navigation.modifyUrl <| toHashUrl <| route


{-| For routes that have a file path query paramter, will  navigate to the same URL but with the file path added as a
query param, otheriwse will do nothing.
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


{-| Returns the query paramater "editingStory" if on the create new story routes and the parameter is present.
-}
getEditingStoryQueryParamOnCreateNewStoryRoute : Route -> Maybe EditingStoryID
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


{-| Returns the query parameter "fromStory" if viewing a snipbit and that query param is present.
-}
getFromStoryQueryParamOnViewSnipbitRoute : Route -> Maybe StoryID
getFromStoryQueryParamOnViewSnipbitRoute route =
    case route of
        ViewSnipbitIntroductionPage fromStoryID _ ->
            fromStoryID

        ViewSnipbitFramePage fromStoryID _ _ ->
            fromStoryID

        ViewSnipbitConclusionPage fromStoryID _ ->
            fromStoryID

        ViewSnipbitQuestionsPage fromStoryID _ ->
            fromStoryID

        ViewSnipbitQuestionPage fromStoryID _ _ _ ->
            fromStoryID

        ViewSnipbitAnswersPage fromStoryID _ _ _ ->
            fromStoryID

        ViewSnipbitAnswerPage fromStoryID _ _ _ ->
            fromStoryID

        ViewSnipbitQuestionCommentsPage fromStoryID _ _ _ _ ->
            fromStoryID

        ViewSnipbitAnswerCommentsPage fromStoryID _ _ _ _ ->
            fromStoryID

        ViewSnipbitAskQuestion fromStoryID _ ->
            fromStoryID

        ViewSnipbitAnswerQuestion fromStoryID _ _ ->
            fromStoryID

        ViewSnipbitEditQuestion fromStoryID _ _ ->
            fromStoryID

        ViewSnipbitEditAnswer fromStoryID _ _ ->
            fromStoryID

        _ ->
            Nothing


{-| Returns query param `touringQuestions` if viewing snipbit and on QA route which has that qp.
-}
getTouringQuestionsQueryParamOnViewSnipbitQARoute : Route -> Maybe MeaninglessString
getTouringQuestionsQueryParamOnViewSnipbitQARoute route =
    case route of
        ViewSnipbitQuestionPage _ touringQuestions _ _ ->
            touringQuestions

        ViewSnipbitAnswersPage _ touringQuestions _ _ ->
            touringQuestions

        ViewSnipbitAnswerPage _ touringQuestions _ _ ->
            touringQuestions

        ViewSnipbitQuestionCommentsPage _ touringQuestions _ _ _ ->
            touringQuestions

        ViewSnipbitAnswerCommentsPage _ touringQuestions _ _ _ ->
            touringQuestions

        _ ->
            Nothing


{-| Returns the query parameter "fromStory" if viewing a bigbit and that query param is present.
-}
getFromStoryQueryParamOnViewBigbitRoute : Route -> Maybe StoryID
getFromStoryQueryParamOnViewBigbitRoute route =
    case route of
        ViewBigbitIntroductionPage fromStoryID _ _ ->
            fromStoryID

        ViewBigbitFramePage fromStoryID _ _ _ ->
            fromStoryID

        ViewBigbitConclusionPage fromStoryID _ _ ->
            fromStoryID

        ViewBigbitQuestionsPage fromStoryID _ ->
            fromStoryID

        ViewBigbitQuestionPage fromStoryID _ _ _ ->
            fromStoryID

        ViewBigbitAnswersPage fromStoryID _ _ _ ->
            fromStoryID

        ViewBigbitAnswerPage fromStoryID _ _ _ ->
            fromStoryID

        ViewBigbitQuestionCommentsPage fromStoryID _ _ _ _ ->
            fromStoryID

        ViewBigbitAnswerCommentsPage fromStoryID _ _ _ _ ->
            fromStoryID

        ViewBigbitAskQuestion fromStoryID _ ->
            fromStoryID

        ViewBigbitEditQuestion fromStoryID _ _ ->
            fromStoryID

        ViewBigbitAnswerQuestion fromStoryID _ _ ->
            fromStoryID

        ViewBigbitEditAnswer fromStoryID _ _ ->
            fromStoryID

        _ ->
            Nothing


{-| Returns query param `touringQuestions` if viewing bigbit and on QA route that has that qp.
-}
getTouringQuestionsQueryParamOnViewBigbitQARoute : Route -> Maybe MeaninglessString
getTouringQuestionsQueryParamOnViewBigbitQARoute route =
    case route of
        ViewBigbitQuestionPage _ touringQuestions _ _ ->
            touringQuestions

        ViewBigbitAnswersPage _ touringQuestions _ _ ->
            touringQuestions

        ViewBigbitAnswerPage _ touringQuestions _ _ ->
            touringQuestions

        ViewBigbitQuestionCommentsPage _ touringQuestions _ _ _ ->
            touringQuestions

        ViewBigbitAnswerCommentsPage _ touringQuestions _ _ _ ->
            touringQuestions

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
viewBigbitPageCurrentActiveFile : Route -> Bigbit.Bigbit -> Maybe QA.BigbitQA -> QA.BigbitQAState -> Maybe FS.Path
viewBigbitPageCurrentActiveFile route bigbit maybeQA qaState =
    let
        getActiveFileBasedOnQuestionID questionID =
            maybeQA
                ||> .questions
                |||> QA.getQuestionByID questionID
                ||> .codePointer
                ||> .file

        getActiveFileBasedOnAnswerID answerID =
            maybeQA
                |||> QA.getQuestionByAnswerID answerID
                ||> .codePointer
                ||> .file
    in
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

            ViewBigbitQuestionsPage _ bigbitID ->
                qaState
                    |> QA.getBrowseCodePointer bigbitID
                    ||> .file

            ViewBigbitQuestionPage _ _ _ questionID ->
                getActiveFileBasedOnQuestionID questionID

            ViewBigbitAnswersPage _ _ _ questionID ->
                getActiveFileBasedOnQuestionID questionID

            ViewBigbitAnswerPage _ _ _ answerID ->
                getActiveFileBasedOnAnswerID answerID

            ViewBigbitQuestionCommentsPage _ _ _ questionID _ ->
                getActiveFileBasedOnQuestionID questionID

            ViewBigbitAnswerCommentsPage _ _ _ answerID _ ->
                getActiveFileBasedOnAnswerID answerID

            ViewBigbitAskQuestion _ bigbitID ->
                qaState
                    |> QA.getNewQuestion bigbitID
                    |||> .codePointer
                    ||> .file

            ViewBigbitEditQuestion _ bigbitID questionID ->
                qaState
                    |> QA.getQuestionEditByID bigbitID questionID
                    ||> .codePointer
                    ||> Editable.getBuffer
                    ||> .file
                    |> (\maybeFileFromEdit ->
                            case maybeFileFromEdit of
                                Nothing ->
                                    getActiveFileBasedOnQuestionID questionID

                                Just fileFromEdit ->
                                    Just fileFromEdit
                       )

            ViewBigbitAnswerQuestion _ _ questionID ->
                getActiveFileBasedOnQuestionID questionID

            ViewBigbitEditAnswer _ _ answerID ->
                getActiveFileBasedOnAnswerID answerID

            _ ->
                Nothing


{-| Get's the ID of the content that we are viewing.
-}
getViewingContentID : Route -> Maybe ContentID
getViewingContentID route =
    case route of
        ViewSnipbitIntroductionPage _ snipbitID ->
            Just snipbitID

        ViewSnipbitConclusionPage _ snipbitID ->
            Just snipbitID

        ViewSnipbitFramePage _ snipbitID _ ->
            Just snipbitID

        ViewSnipbitQuestionsPage _ snipbitID ->
            Just snipbitID

        ViewSnipbitQuestionPage _ _ snipbitID _ ->
            Just snipbitID

        ViewSnipbitAnswersPage _ _ snipbitID _ ->
            Just snipbitID

        ViewSnipbitAnswerPage _ _ snipbitID _ ->
            Just snipbitID

        ViewSnipbitQuestionCommentsPage _ _ snipbitID _ _ ->
            Just snipbitID

        ViewSnipbitAnswerCommentsPage _ _ snipbitID _ _ ->
            Just snipbitID

        ViewSnipbitAskQuestion _ snipbitID ->
            Just snipbitID

        ViewSnipbitAnswerQuestion _ snipbitID _ ->
            Just snipbitID

        ViewSnipbitEditQuestion _ snipbitID _ ->
            Just snipbitID

        ViewSnipbitEditAnswer _ snipbitID _ ->
            Just snipbitID

        ViewBigbitIntroductionPage _ bigbitID _ ->
            Just bigbitID

        ViewBigbitFramePage _ bigbitID _ _ ->
            Just bigbitID

        ViewBigbitConclusionPage _ bigbitID _ ->
            Just bigbitID

        ViewBigbitQuestionsPage _ bigbitID ->
            Just bigbitID

        ViewBigbitQuestionPage _ _ bigbitID _ ->
            Just bigbitID

        ViewBigbitAnswersPage _ _ bigbitID _ ->
            Just bigbitID

        ViewBigbitAnswerPage _ _ bigbitID _ ->
            Just bigbitID

        ViewBigbitQuestionCommentsPage _ _ bigbitID _ _ ->
            Just bigbitID

        ViewBigbitAnswerCommentsPage _ _ bigbitID _ _ ->
            Just bigbitID

        ViewBigbitAskQuestion _ bigbitID ->
            Just bigbitID

        ViewBigbitEditQuestion _ bigbitID _ ->
            Just bigbitID

        ViewBigbitAnswerQuestion _ bigbitID _ ->
            Just bigbitID

        ViewBigbitEditAnswer _ bigbitID _ ->
            Just bigbitID

        ViewStoryPage storyID ->
            Just storyID

        _ ->
            Nothing


{-| Returns true if on one of the viewing snipbit QA routes.
-}
isOnViewSnipbitQARoute : Route -> Bool
isOnViewSnipbitQARoute route =
    case route of
        ViewSnipbitQuestionsPage _ _ ->
            True

        ViewSnipbitQuestionPage _ _ _ _ ->
            True

        ViewSnipbitAnswersPage _ _ _ _ ->
            True

        ViewSnipbitAnswerPage _ _ _ _ ->
            True

        ViewSnipbitQuestionCommentsPage _ _ _ _ _ ->
            True

        ViewSnipbitAnswerCommentsPage _ _ _ _ _ ->
            True

        ViewSnipbitAskQuestion _ _ ->
            True

        ViewSnipbitAnswerQuestion _ _ _ ->
            True

        ViewSnipbitEditQuestion _ _ _ ->
            True

        ViewSnipbitEditAnswer _ _ _ ->
            True

        _ ->
            False


{-| Returns true if on one of the tutorial routes.
-}
isOnViewSnipbitTutorialRoute : Route -> Bool
isOnViewSnipbitTutorialRoute route =
    case route of
        ViewSnipbitIntroductionPage _ _ ->
            True

        ViewSnipbitFramePage _ _ _ ->
            True

        ViewSnipbitConclusionPage _ _ ->
            True

        _ ->
            False


{-| Returns true if on one of the viewing bigbit QA routes.
-}
isOnViewBigbitQARoute : Route -> Bool
isOnViewBigbitQARoute route =
    case route of
        ViewBigbitQuestionsPage _ _ ->
            True

        ViewBigbitQuestionPage _ _ _ _ ->
            True

        ViewBigbitAnswersPage _ _ _ _ ->
            True

        ViewBigbitAnswerPage _ _ _ _ ->
            True

        ViewBigbitQuestionCommentsPage _ _ _ _ _ ->
            True

        ViewBigbitAnswerCommentsPage _ _ _ _ _ ->
            True

        ViewBigbitAskQuestion _ _ ->
            True

        ViewBigbitEditQuestion _ _ _ ->
            True

        ViewBigbitAnswerQuestion _ _ _ ->
            True

        ViewBigbitEditAnswer _ _ _ ->
            True

        _ ->
            False


{-| Returns true if on one of the viewing bigbit tutorial routes.
-}
isOnViewBigbitTutorialRoute : Route -> Bool
isOnViewBigbitTutorialRoute route =
    case route of
        ViewBigbitIntroductionPage _ _ _ ->
            True

        ViewBigbitFramePage _ _ _ _ ->
            True

        ViewBigbitConclusionPage _ _ _ ->
            True

        _ ->
            False
